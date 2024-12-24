import gleam/int
import gleam/dict
import gleam/list
import gleam/io
import gleam/string
import gleam/set
import gleam/option
import rememo/memo
import simplifile as file

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day23.txt")
    let connections = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(connections)))
    io.println("Part 2: " <> part2(connections))
}

pub fn part2(connections: dict.Dict(String, set.Set(String))) -> String {
    maximum_clique(connections)
    |> set.to_list
    |> list.sort(string.compare)
    |> string.join(",")
}

pub fn maximum_clique(connections: dict.Dict(String, set.Set(String))) -> set.Set(String) {
    let seeds = dict.keys(connections)
    let candidates = set.from_list(seeds)
    let maximal_cliques = seeds
        |> list.map(fn(seed) {
            let initial_clique = set.from_list([seed])
            use cache <- memo.create()
            maximal_clique(initial_clique, set.difference(candidates, initial_clique), connections, cache)
        })
    maximal_cliques
    |> list.fold(set.new(), fn(acc, clique) {
        case set.size(clique) > set.size(acc) {
            True -> clique
            False -> acc
        }
    })
}

pub fn maximal_clique(clique: set.Set(String), candidates: set.Set(String), connections: dict.Dict(String, set.Set(String)), cache) -> set.Set(String) {
    case set.to_list(candidates) {
        [] -> clique
        [candidate, ..remaining] -> {
            // TODO: This caching logic is not correct and leads to very long run times.
            //       Switch to using the Bron Kerbosch algorithm instead.
            use <- memo.memoize(cache, #(clique, candidate))
            let remaining = set.from_list(remaining)
            let valid = clique
                |> set.to_list
                |> list.all(fn(member) {
                    let assert Ok(conns) = dict.get(connections, member)
                    set.contains(conns, candidate)
                })
            case valid {
                False -> maximal_clique(clique, remaining, connections, cache)
                True -> {
                    let with = maximal_clique(set.insert(clique, candidate), remaining, connections, cache)
                    let without = maximal_clique(clique, remaining, connections, cache)
                    case set.size(with) > set.size(without) {
                        True -> with
                        False -> without
                    }
                }
            }
        }
    }
}

pub fn part1(connections: dict.Dict(String, set.Set(String))) -> Int {
    let trips = triplets(
        connections: connections,
        unseen: connections |> dict.keys |> set.from_list,
        seen: set.new(),
        result: set.new(),
    )
    trips
    |> set.to_list
    |> list.count(fn(triplet) { list.any(triplet, string.starts_with(_, "t")) })
}

// Dijksta-eqsue algorithm.  Recursive with "seen", "unseen" and "result"
pub fn triplets(connections connections: dict.Dict(String, set.Set(String)), unseen unseen: set.Set(String), seen seen: set.Set(String), result result: set.Set(List(String))) -> set.Set(List(String)) {
    case set.to_list(unseen) {
        [] -> result
        [chosen, .._] -> {
            let assert Ok(all_links) = dict.get(connections, chosen)
            // Remove the already seen nodes from the set of links.
            // This prevents double counting (since the already seen
            // node would have considered `chosen` in a previous iteration).
            let valid_links = set.difference(all_links, seen)
            let all_pairs = valid_links
                |> set.to_list
                |> list.combinations(2)
            let valid_pairs = all_pairs
                |> list.filter_map(fn(pair) {
                    let assert [a, b] = pair
                    let assert Ok(a_links) = dict.get(connections, a)
                    let assert Ok(b_links) = dict.get(connections, b)
                    case set.contains(a_links, b) && set.contains(b_links, a) {
                        True -> Ok(#(a, b))
                        False -> Error(Nil)
                    }
                })
            let new_unseen = set.delete(unseen, chosen)
            let new_seen = set.insert(seen, chosen)
            let new_result = list.fold(valid_pairs, result, fn(acc, pair) {
                let a = chosen
                let #(b, c) = pair
                set.insert(acc, [a, b, c])
            })
            triplets(connections, new_unseen, new_seen, new_result)
        }
    }
}

pub fn parse(contents: String) -> dict.Dict(String, set.Set(String)) {
    let connections = contents
        |> string.split("\n")
        |> list.fold(dict.new(), fn(connections, row) {
            let assert [left, right] = string.split(row, "-")
            connections
            |> dict.upsert(left, fn(x) {
                case x {
                    option.Some(s) -> set.insert(s, right)
                    option.None -> set.from_list([right])
                }
            })
            |> dict.upsert(right, fn(x) {
                case x {
                    option.Some(s) -> set.insert(s, left)
                    option.None -> set.from_list([left])
                }
            })
        })
    connections
}