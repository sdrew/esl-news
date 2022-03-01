defmodule EslNews do
  @moduledoc """
  `EslNews` works as an aggeregator for Hacker News stories, fetching data from the HN API for further
  analysis or consumption.
  - Documentation for `EslNews` is available at https://sdrew.github.io/esl-news/
  - Documentation for the HN API is available at https://github.com/HackerNews/API

  ### Basic Features
  - Fetch the 50 top stories every 5 minutes.
  - Makes stories available via two public APIs
    - JSON over HTTP
    - JSON over WebSockets
  - `EslNews` tries to make use of the fewest external dependencies, without being too inconvenient.

  ### Public APIs
  - `/api/stories`
    - The endpoint accepts pagination parameters for the most recent list of stories.
      - `page` - Default: `1`
      - `per` - Default: `10`
  - `/api/stories/[:story_id]`
    - Display JSON for a single story
  - `/api/ws`
    - The WebSockets endpoint delivers the most recent 50 stories.
    - The list is re-sent to the client every 20 seconds, including any story updates.

  ### Storage
  `EslNews` requires no external storage, all stories are stored in memory using `:mnesia`.

  ### Web server
  `EslNews` provides a webserver directly using `:cowboy`, and includes a simple Javascript WebSockets client
  to display stories on the homepage (`/`) for testing.

  ### Workers
  - `EslNews.Http.SyncLists` will update the list of story IDs using the HN API every 5 minutes. It will then
  push these story IDs into a processing queue for `EslNews.Http.SyncItems`
  - `EslNews.Http.SyncItems` will update each story using the HN API.
    - Existing stories will not be re-fetched.
    - Multiple workers will be spawned by the supervisor depending on `MIX_ENV`
      - `:dev` 4 workers
      - `:prod` 10 workers

  ### Supervision Tree
  ![Supervsion Tree for :dev environment](./supervisor_tree.png)
  """
end
