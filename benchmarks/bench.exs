{:ok, []} = Application.ensure_all_started(:redis_benches)

RedisBenches.Redix.command(["FLUSHDB"])
size = 1_000_000

inputs = %{
  "small" => 750,
  "large" => 800,
  "xlarge" => 850
}

get_num = fn -> 1..size |> Enum.random() end

async_hset_fn = fn x ->
  Task.async(fn ->
    command_1 = ["HSET", "myhash", "mykey#{x}", "myval#{x}"]
    {:ok, _} = RedisBenches.Redix.command(command_1)
  end)
end

async_set_fn = fn x ->
  Task.async(fn ->
    command_1 = ["SADD", "myset", "#{x}"]
    {:ok, _} = RedisBenches.Redix.command(command_1)
  end)
end

async_sorted_set_fn = fn x ->
  Task.async(fn ->
    command_1 = ["ZADD", "myzset", "#{x}"]
    {:ok, _} = RedisBenches.Redix.command(command_1)
  end)
end

do_work_fn = fn x, our_fn ->
  1..size
  |> Enum.chunk_every(x)
  |> Enum.map(fn chunk ->
    Enum.map(chunk, our_fn)
    |> Enum.map(&Task.await/1)
  end)
end

do_work_fn.(800, async_hset_fn)
do_work_fn.(800, async_set_fn)

rollout_string =
  1..size
  |> Enum.shuffle()
  |> Enum.join(",")

command_1 = ["SET", "rollout", rollout_string]
{:ok, _} = RedisBenches.Redix.command(command_1)

retrieve_rollout = fn x ->
  command_2 = ["GET", "rollout"]
  {:ok, returned_value} = RedisBenches.Redix.command(command_2)

  mem =
    returned_value
    |> String.split(",")
    |> Enum.member?(x)
end

retrieve_hmap = fn x ->
  command_2 = ["HGET", "myhash", "mykey#{x}"]
  {:ok, returned_value} = RedisBenches.Redix.command(command_2)
end

retrieve_set = fn x ->
  command_2 = ["SISMEMBER", "myset", "#{x}"]
  {:ok, returned_value} = RedisBenches.Redix.command(command_2)
end

retrieve_full_set = fn x ->
  command_2 = ["SMEMBERS", "myset"]
  {:ok, returned_value} = RedisBenches.Redix.command(command_2)
  Enum.member?(returned_value, "#{x}")
end

retrieve_hmap_getall = fn x ->
  command_2 = ["HGETALL", "myhash"]

  {:ok, returned_value} = RedisBenches.Redix.command(command_2)

  hmap =
    returned_value
    |> Enum.chunk_every(2)
    |> Enum.map(fn [k, v] -> {k, v} end)
    |> Map.new()
    |> Map.get(x)
end

Benchee.run(
  %{
    "rollout" => fn num -> retrieve_rollout.(num) end,
    "hmap_hget" => fn num -> retrieve_hmap.(num) end,
    "hmap_hgetall" => fn num -> retrieve_hmap_getall.(num) end,
    "set_ismember" => fn num -> retrieve_set.(num) end,
    "set_full_retrieve" => fn num -> retrieve_full_set.(num) end
  },
  before_each: fn _ -> get_num.() end
)

require IEx
IEx.pry()
