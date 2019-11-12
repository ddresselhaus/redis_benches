defmodule RedisBenches.LuaFetch do
  def ff_for_user(user_id) do
    '''
    local function union ( a, b )
        local result = {}
        for k,v in pairs ( a ) do
            table.insert( result, v )
        end
        for k,v in pairs ( b ) do
             table.insert( result, v )
        end
        return result
    end

    local groups = redis.call('SMEMBERS', 'groups')
    local user_groups = {}

    for i,v in ipairs(groups) do
      local member = redis.call('SISMEMBER', 'group-' .. v .. '-user-id', '#{user_id}')
      if member == 1 then
        table.insert(user_groups, 'group-' .. v .. '-ff')
      end
    end

    local ffs = redis.call('SUNION', unpack(user_groups))

    return ffs
    '''
  end

  def script do
    '''
    local login = redis.call('hget', KEYS[1], 'login')
    Fetch the user’s login name from their ID; remember that tables in Lua are 1-indexed, not 0-indexed like Python and most other languages.

    if not login then
        return false
    If there’s no login, return that no login was found.

    end
    local id = redis.call('incr', KEYS[2])
    Get a new ID for the status message.

    local key = string.format('status:%s', id)
    Prepare the destination key for the status message.

    redis.call('hmset', key,
        'login', login,
        'id', id,
        unpack(ARGV))
    Set the data for the status message.

    redis.call('hincrby', KEYS[1], 'posts', 1)
    Increment the post count of the user.

    return id
    Return the ID of the status message.

    '''
  end
end
