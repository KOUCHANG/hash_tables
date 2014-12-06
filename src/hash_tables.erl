-module(hash_tables).

-export([
         new/1,
         put/3,
         update/3,
         get/2,
         find/2,
         remove/2,
         from_list/2,
         to_list/1,
         rehash/2
        ]).

-export_type([
              hash_table/0
             ]).

-record(hash_table,
        {
          size = 0 :: integer(),
          hash_fun = fun erlang:hash/2 :: fun((term())->integer()),
          data = {} :: tuple()
        }).
-opaque hash_table() :: #hash_table{}.

-spec new(Size::integer()) -> hash_table().
new(Size) ->
    #hash_table{size = Size, data = list_to_tuple(lists:map(fun (_) -> [] end, lists:seq(1, Size)))}.

-spec put(Key::term(), Value::term(), hash_table()) -> hash_table().
put(Key, Value, #hash_table{size = Size, hash_fun = HashFun, data = Data} = HashTable) ->
    Hash = HashFun(Key, Size),
    Pre = element(Hash, Data),
    HashTable#hash_table{data = setelement(Hash, Data, [{Key, Value} | Pre])}.

-spec update(Key::term(), Value::term(), hash_table()) -> hash_table().
update(Key, Value, HashTable) ->
    try get(Key, HashTable) of
        _ ->
            put(Key, Value, HashTable)
    catch
        error:bad_key ->
            error(badarg)
    end.

-spec get(Key::term(), hash_table()) -> Value::term().
get(Key, HashTable) ->
    case find(Key, HashTable) of
        error ->
            error(bad_key);
        {ok, Value} ->
            Value
    end.

-spec find(Key::term(), hash_table()) -> {ok, Value::term()} | error.
find(Key, #hash_table{size = Size, hash_fun = HashFun, data = Data}) ->
    Hash = HashFun(Key, Size),
    List = element(Hash, Data),
    case proplists:lookup(Key, List) of
        none ->
            error;
        {Key, Value} ->
            {ok, Value}
    end.

-spec remove(Key::term(), hash_table()) -> hash_table().
remove(Key, #hash_table{size = Size, hash_fun = HashFun, data = Data} = HashTable) ->
    Hash = HashFun(Key, Size),
    Pre = element(Hash, Data),
    HashTable#hash_table{data = setelement(Hash, Data, proplists:delete(Key, Pre))}.

-spec from_list([{Key::term(), Value::term()}], Size::integer()) -> hash_table().
from_list(List, Size) ->
    lists:foldr(
      fun ({Key, Value}, Acc) ->
              put(Key, Value, Acc)
      end, new(Size), List).

-spec to_list(hash_table()) -> [{Key::term(), Value::term()}].
to_list(#hash_table{data = Data}) ->
    lists:flatten(tuple_to_list(Data)).

-spec rehash(Size::integer(), hash_table()) -> hash_table().
rehash(Size, HashTable) ->
    from_list(to_list(HashTable), Size).

