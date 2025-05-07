Benchee.run(
  %{
    "default_dump" => fn tids -> Peep.Storage.Striped.get_all_metrics(tids) end,
    "new_dump" => fn tids -> Peep.Storage.Striped2.get_all_metrics(tids) end
  },
  # profile_after: true,
  before_scenario: fn _ ->
    tids = Peep.Storage.Striped.new()

    sample_metrics =
      [
        Telemetry.Metrics.counter("benchmark.counter", description: "counter"),
        Telemetry.Metrics.sum("benchmark.sum", description: "sum"),
        Telemetry.Metrics.last_value("benchmark.last_value", description: "last_value"),
        Telemetry.Metrics.distribution("benchmark.distribution", description: "distribution")
      ]

    1..150_000
    |> Task.async_stream(fn _ ->
      Peep.Storage.Striped.insert_metric(
        tids,
        Enum.random(sample_metrics),
        Enum.random(10..1000),
        %{foo: Enum.random(1..10), bar: :baz}
      )
    end)
    |> Stream.run()

    tids
  end
)
