defmodule RedisBenches.Redix do
  @pool_size 10

  def child_spec(_args) do
    uri = Application.get_env(:dialer_backend, :redis_url, "redis://localhost")
    # Specs for the Redix connections.
    children =
      for i <- 0..(@pool_size - 1) do
        Supervisor.child_spec({Redix, {uri, name: :"redix_#{i}"}}, id: {Redix, i})
      end

    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command) do
    Redix.command(:"redix_#{random_index()}", command)
  end

  def command!(command) do
    Redix.command!(:"redix_#{random_index()}", command)
  end

  def pipeline(pipeline) do
    Redix.pipeline(:"redix_#{random_index()}", pipeline)
  end

  def pipeline!(pipeline) do
    Redix.pipeline!(:"redix_#{random_index()}", pipeline)
  end

  defp random_index() do
    rem(System.unique_integer([:positive]), @pool_size)
  end
end
