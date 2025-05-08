defmodule Fixture do
  def sample_metrics,
    do: [
      Telemetry.Metrics.counter("benchmark.counter", description: "counter"),
      Telemetry.Metrics.sum("benchmark.sum", description: "sum"),
      Telemetry.Metrics.last_value("benchmark.last_value", description: "last_value"),
      Telemetry.Metrics.distribution("benchmark.distribution", description: "distribution")
    ]
end

Benchee.run(
  %{
    "default_dump" => fn {tids, _} -> Peep.Storage.Striped.get_all_metrics(tids) end,
    "new_dump" => fn {tids, _} -> Peep.Storage.Striped2.get_all_metrics(tids) end
  },
  inputs: %{
    "small" =>
      {Peep.Storage.Striped.new(),
       Enum.map(1..100, fn _ ->
         [
           Enum.random(Fixture.sample_metrics()),
           Enum.random(10..1000),
           %{foo: Enum.random(1..10), bar: :baz}
         ]
       end)},
    "medium" =>
      {Peep.Storage.Striped.new(),
       Enum.map(1..10_000, fn _ ->
         [
           Enum.random(Fixture.sample_metrics()),
           Enum.random(10..1000),
           %{foo: Enum.random(1..10), bar: :baz}
         ]
       end)},
    "large" =>
      {Peep.Storage.Striped.new(),
       Enum.map(1..150_000, fn _ ->
         [
           Enum.random(Fixture.sample_metrics()),
           Enum.random(10..1000),
           %{foo: Enum.random(1..10), bar: :baz}
         ]
       end)}
  },
  # profile_after: true,
  before_scenario: fn {tids, metrics} ->
    metrics
    |> Task.async_stream(fn [metric, value, tags] ->
      Peep.Storage.Striped.insert_metric(tids, metric, value, tags)
    end)
    |> Stream.run()

    {tids, metrics}
  end
)
