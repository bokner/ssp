defmodule SSP.Batch do
  require Logger

  def solvers() do
    ["cplex", "or-tools", "gecode", "yuck", "fzn-oscar-cbls"]
  end

  def run_multiple(instance_files, solvers \\ solvers(), opts) do
    instance_num = length(instance_files)

    instance_files
    |> Enum.with_index(1)
    |> Enum.map(fn {instance, idx} ->
      Logger.info("Instance: #{instance} (#{idx} of #{instance_num})")
      %{instance: instance, results: run(instance, solvers, opts)}
    end)
  end

  def run(instance_file, solvers \\ solvers(), opts)

  def run(instance_file, solvers, opts) do
    (Keyword.get(opts, :sync) && run_sync(instance_file, solvers, opts)) ||
      run_async(instance_file, solvers, opts)
  end

  def run_sync(instance_file, solvers, opts) do
    Enum.map(solvers, fn solver ->
      SSP.run(instance_file, Keyword.merge([solver: solver], opts))
    end)
  end

  def run_async(instance_file, solvers, opts) do
    Task.async_stream(
      solvers,
      fn solver ->
        instance_file
        |> SSP.run(Keyword.merge([solver: solver], opts))
      end,
      max_concurrency: length(solvers()),
      timeout: opts[:time_limit] * 2
    )
    |> Enum.map(fn {:ok, res} ->
      res
    end)
  end
end
