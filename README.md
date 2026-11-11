> **Note:** this is not my main GitHub account. My main profile is [github.com/carlosdanielpohlod](https://github.com/carlosdanielpohlod) and my portfolio is at [carlospohlod.com](https://carlospohlod.com).

# Weather Forecast

A Rails 8.1 app that takes a US street address and shows the current temperature and a 7-day forecast with daily highs and lows. Forecasts are cached for 30 minutes per zip code, and the page shows whether a result came live from the API or from the cache.

## Running the app

### With Docker

```bash
docker compose up --build
```

Then open http://localhost:3000.

The container runs Rails in production mode with Solid Cache, configured for local evaluation over HTTP. No API keys or credentials are needed.

### Locally

Requirements: Ruby 3.4.12 (see `.ruby-version`) and SQLite.

```bash
bin/setup --skip-server
bin/dev
```

`bin/dev` starts the Rails server and the Tailwind watcher together. Open http://localhost:3000.

Try an address such as `1600 Pennsylvania Ave NW, Washington, DC` or `100 Main St, Springfield`. The second one matches several towns and shows the "other addresses" selector.

### Tests

```bash
bin/rails test
bin/rails test:system
```

The second command runs browser tests in headless Chrome. They cover a search, switching to another matching address and the cached badge. External APIs are stubbed with WebMock in both suites, so they run offline.

## Choosing the APIs

Both APIs are free and need no API key, so anyone can clone the repo and run it right away.

### Geocoding: US Census Geocoder

I first used the Google Geocoding API. It is the most flexible option, but it requires an API key and a billing account, even within its free monthly quota. That would force every reviewer to create a Google Cloud project before seeing the app.

I switched to the [US Census Geocoder](https://geocoding.geo.census.gov/geocoder/). It is a free public service from the US government, with no key and no sign-up. It returns the coordinates, the zip code and every address that matches the search.

The trade-off is coverage:

- It only covers US addresses.
- It needs a full street address with number and street. A city name or a zip code alone returns no match.

The app resolves the address to coordinates and fetches the forecast for that exact point. As an implementation decision, that forecast is then shared for 30 minutes by every address in the same zip code. A full street address is all this flow needs, so the Census coverage is enough here. When the geocoder finds nothing, the app asks for a full US street address.

### Weather: Open-Meteo

[Open-Meteo](https://open-meteo.com/) is free for non-commercial use and needs no key. One request returns the current temperature and the daily highs and lows for 7 days, in Fahrenheit and in the local time zone of the address.

## Handling more than one matching address

The same street address can exist in several towns. `100 Main St, Springfield`, for example, can match addresses in several states. Each one has its own zip code, so each one has its own forecast and its own cache entry.

Picking the first match silently could show the weather for the wrong place. Rejecting the search would make the user guess what is missing. So the app does both things a person would expect:

- It shows the forecast for the first match returned by the geocoder right away.
- Below the forecast, it lists the other matching addresses, each with its zip code. Choosing one loads that forecast.

The URL keeps the index of the selected address. When the search matches a single address, the list is hidden.

## How it works

1. `ForecastsController` validates the address with a small ActiveModel form object, `ForecastSearch`. A blank address redirects back with a flash message.
2. `ForecastService` runs the flow:
   - `CensusGeocoder` turns the address into a list of locations.
   - It picks the selected location, or the first match by default.
   - It reads the forecast from the cache by zip code. On a miss, it calls `OpenMeteoForecaster` and stores the result for 30 minutes.
3. The view shows a "Live" or "Cached" badge with the time of the original fetch.

### Caching

| What | Key | TTL |
|---|---|---|
| Forecast | zip code | 30 minutes |
| Geocoding | normalized address | 1 day |

Only successful responses are cached, so a temporary API failure is retried on the next request. Cache entries use plain hashes to reduce coupling to application classes. Cache keys are versioned to support changes to the stored structure.

The cache store is Solid Cache in production and an in-memory store in development.

### Design decisions

- **Result objects instead of exceptions.** HTTP clients and services return a success or failure result. Errors are handled where they happen, and the controller only decides what to render.
- **Thin API clients.** `UsCensus::Geocoder::Client` and `OpenMeteo::Client` only build the request. A shared `Http::Client` wraps Faraday with timeouts and never logs the full URL.
- **Trusting the API contract.** The services handle what the APIs document, such as no matches or a missing temperature. They don't defend against every possible malformed response.
- **Hotwire.** Choosing another address from the dropdown reloads only the forecast card through a Turbo Frame, and the URL still updates. A small Stimulus controller submits the dropdown, and the search button shows a loading state.

## What I would improve

- Handle incomplete or malformed API responses as a clear failure instead of an error page.
