defmodule Magnetissimo.Crawlers.EZTV do
  use GenServer
  import SweetXml
  require Logger
  alias Magnetissimo.{Torrent, Crawler, Parser}

  @site_name "EZTV"
  @site_display_name @site_name
  @site_url "https://eztv.io/ezrss.xml"
  @period 15 * 60 * 1000

  @xml_map [
    ~x"//channel/item"l,
    name: ~x"./title/text()",
    canonical_url: ~x"./link/text()",
    published_at: ~x"./pubDate/text()",
    magnet_url: ~x"./torrent:magnetURI/text()",
    seeds: ~x"./torrent:seeds/text()",
    leechers: ~x"./torrent:peers/text()",
    size: ~x"./torrent:contentLength/text()"
  ]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(state) do
    Process.send_after(self(), :rss_fetch, 60 * 1000)
    {:ok, state}
  end

  def handle_info(:rss_fetch, state) do
    case Crawler.get_torrents_from_feed(@site_url, @xml_map) do
      {:ok, torrents} -> save_torrents(torrents)
      _ -> Logger.warn("[#{@site_name}] There was a problem getting the feed: #{@site_url}")
    end

    schedule_rss_fetch()
    {:noreply, state}
  end

  defp save_torrents(data) when is_list(data) do
    Logger.debug("[#{@site_name}] Saving torrents.")
    Enum.each(data, fn torrent_data -> save_torrents(torrent_data) end)
  end
  defp save_torrents(data) when is_map(data) do
    Torrent.changeset(%Torrent{}, %{
      name: List.to_string(data.name),
      canonical_url: List.to_string(data.canonical_url),
      magnet_url: List.to_string(data.magnet_url),
      leechers: Parser.bytes(data.leechers),
      seeds: Parser.bytes(data.seeds),
      website_source: @site_display_name,
      size: Parser.bytes(data.size),
      published_at: Parser.pubdate(data.published_at, "{RFC1123}"),
      magnet_hash: Parser.magnet_hash(data.magnet_url)
    }) |> Torrent.save
  end
  defp save_torrents(_data) do :ok end

  defp schedule_rss_fetch do
    Process.send_after(self(), :rss_fetch, @period)
  end
end
