defmodule EslNews.Test.TestHelper do
  @fixtures_dir Path.join([File.cwd!(), "test", "fixtures"])

  @doc """
  Load JSON fixture files into a map indexed by filename
  """
  @spec load_fixtures(String.t(), [String.t(), ...]) :: map
  def load_fixtures(scope, keys) do
    keys
    |> Enum.map(fn key ->
      fixture =
        Path.join([@fixtures_dir, scope, "#{key}.json"])
        |> File.read!()
        |> Jason.decode!()
        |> Map.new(fn {key, value} ->
          {String.to_atom(key), value}
        end)

      {key, fixture}
    end)
    |> Enum.into(%{})
  end
end

ExUnit.start()
