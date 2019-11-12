defmodule RedisBenches.LuaFetchTest do
  use ExUnit.Case
  alias RedisBenches.LuaFetch

  setup do
    RedisBenches.Redix.command(["FLUSHDB"])

    on_exit(fn ->
      RedisBenches.Redix.command(["FLUSHDB"])
    end)
  end

  test "works" do
    ff_key = "feature_flags"
    groups_key = "groups"
    group_user_key = fn group -> "group-#{group}-user-id" end
    group_ff_key = fn group -> "group-#{group}-ff" end

    feature_flag_1 = "pony_express"
    feature_flag_2 = "multipass"
    group_1 = "alpha"
    group_2 = "beta"
    user_id_1 = 1
    user_id_2 = 2

    commands = [
      ["SADD", ff_key, feature_flag_1],
      ["SADD", ff_key, feature_flag_2],
      ["SADD", groups_key, group_1],
      ["SADD", groups_key, group_2],
      ["SADD", group_user_key.(group_1), user_id_1],
      ["SADD", group_user_key.(group_2), user_id_1],
      ["SADD", group_user_key.(group_2), user_id_2],
      ["SADD", group_ff_key.(group_1), feature_flag_1],
      ["SADD", group_ff_key.(group_2), feature_flag_2]
    ]

    {:ok, result} = RedisBenches.Redix.pipeline(commands)

    script = RedisBenches.LuaFetch.ff_for_user(user_id_1)
    {:ok, sha} = RedisBenches.Redix.command(["SCRIPT", "LOAD", script])
    assert is_binary(sha)
    assert RedisBenches.Redix.command(["SCRIPT", "EXISTS", sha, "foo"]) == {:ok, [1, 0]}

    # Eval'ing the script
    # assert RedisBenches.Redix.command(["EVALSHA", sha, 0]) == {:ok, "hello world"}
    a = RedisBenches.Redix.command(["EVALSHA", sha, 0])
    require IEx
    IEx.pry()
  end
end
