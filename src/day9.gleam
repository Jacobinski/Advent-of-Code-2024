import gleam/option
import gleam/result
import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/string
import gleam/string_tree
import simplifile as file

pub type Block {
    Empty
    File(id: String)
}

pub fn parse1(contents: String) -> List(Block) {
    contents
    |> string.to_graphemes
    |> list.index_map(fn(x, idx){
        let is_file = int.is_even(idx)
        let assert Ok(times) = int.parse(x)
        case is_file {
            False -> list.repeat(Empty, times: times)
            True -> list.repeat(File(id: int.to_string(idx / 2)), times: times)
        }
    })
    |> list.flatten
}

fn pretty_print(memory: List(Block)) {
    pretty_print_helper(string_tree.new(), memory)
    |> string_tree.to_string
    |> io.debug
    memory
}

fn pretty_print_helper(acc: string_tree.StringTree, memory: List(Block)) -> string_tree.StringTree {
    case memory {
        [] -> acc
        [first, ..rest] -> case first {
            Empty -> pretty_print_helper(string_tree.append(acc, "."), rest)
            File(id) -> pretty_print_helper(string_tree.append(acc, id), rest)
        }
    }
}

fn defragment(memory: List(Block)) -> List(Block) {
    defragment_helper([], [], memory)
}

fn defragment_helper(acc_full: List(Block), acc_empty: List(Block), memory: List(Block)) -> List(Block) {
    case memory {
        // Case 0: Base case of no memory left to parse. Return combination of [full, empty]
        [] -> list.append(acc_full, acc_empty)
        [first, ..rest_mem] -> case first {
            // Case 1: First block has a file. Save this in full acc and recurse on smaller memory.
            File(id) -> defragment_helper(list.append(acc_full, [File(id)]), acc_empty, rest_mem)
            // Case 2: First block is empty...
            Empty -> {
                case list.reverse(rest_mem) {
                    // Case 2A: ... and there is no further memory. Append to the empty acc and recurse.
                    [] -> defragment_helper(acc_full, list.append(acc_empty, [Empty]), [])
                    // Case 2B: ... and there is more memory ...
                    [back, ..rest_mem_no_back_reverse] -> case back {
                        // Case 2B1: ... and the back memory is empty. Append it to empty acc and recurse.
                        Empty -> defragment_helper(
                            acc_full,
                            list.append(acc_empty, [Empty]),
                            // Keep the memory the front memory in the original state (empty first); remove the back
                            list.append([first], list.reverse(rest_mem_no_back_reverse))
                        )
                        // Case 2B1: ... and the back memory is full. Append it to full acc and append the
                        File(id_back) -> defragment_helper(
                            // Add the back memory to the acc_full
                            list.append(acc_full, [File(id_back)]),
                            // Add the front memory to the acc_empty
                            list.append(acc_empty, [Empty]),
                            // Recurse on the shortened memory (2 units shorter)
                            list.reverse(rest_mem_no_back_reverse)
                        )
                    }
                }
            }
        }
    }
}

pub fn part1(memory: List(Block)) -> Int {
    memory
    // |> pretty_print
    |> defragment
    // |> pretty_print
    |> list.index_map(fn(block, idx) {
        case block {
            Empty -> 0
            File(id) -> {
                let assert Ok(x) = int.parse(id)
                idx * x
            }
        }
    })
    |> list.reduce(int.add)
    |> result.unwrap(0)
}

pub type Block2 {
    Empty2(length: Int)
    File2(length: Int, id: String)
}

pub fn parse2(contents: String) -> List(Block2) {
    contents
    |> string.to_graphemes
    |> list.index_map(fn(x, idx){
        let is_file = int.is_even(idx)
        let assert Ok(times) = int.parse(x)
        case is_file {
            False -> Empty2(length: times)
            True -> File2(length: times, id: int.to_string(idx / 2))
        }
    })
}

fn to_string(block: Block2) -> String {
    case block {
        Empty2(len) -> string.repeat(".", len)
        File2(len, id) -> string.repeat(id, len)
    }
}

fn pretty_print2(memory: List(Block2)) {
    pretty_print_helper2(string_tree.new(), memory)
    |> string_tree.to_string
    |> io.debug
    memory
}

fn pretty_print_helper2(acc: string_tree.StringTree, memory: List(Block2)) -> string_tree.StringTree {
    case memory {
        [] -> acc
        [first, ..rest] -> pretty_print_helper2(string_tree.append(acc, to_string(first)), rest)
    }
}

fn defragment2(memory: List(Block2)) -> List(Block2) {
    defragment_helper2([], memory)
}

fn defragment_helper2(acc: List(Block2), memory: List(Block2)) -> List(Block2) {
    case memory {
        [] -> acc
        [front, ..rest] -> case front {
            File2(len, id) -> defragment_helper2(
                list.append(acc, [File2(len, id)]),
                rest,
            )
            Empty2(len) -> {
                // Attempt to find something to fit inside the empty space
                case remove_file(rest, len) {
                    // Nothing found. Skip over this memory block.
                    option.None -> defragment_helper2(
                        list.append(acc, [Empty2(len)]),
                        rest
                    )
                    option.Some(#(file, new_memory)) -> {
                        let assert File2(f2_len, f2_id) = file
                        case f2_len < len {
                            // We need to leave some partial memory at the front of the memory
                            True -> defragment_helper2(
                                list.append(acc, [File2(f2_len, f2_id)]),
                                list.append([Empty2(len - f2_len)], new_memory)
                            )
                            // Leave nothing
                            False -> defragment_helper2(
                                list.append(acc, [File2(f2_len, f2_id)]),
                                new_memory,
                            )
                        }
                    }
                }
            }
        }
    }
}

fn remove_file(memory: List(Block2), want_len: Int) -> option.Option(#(Block2, List(Block2))) {
    let match = memory
        |> list.reverse
        |> list.fold(Empty2(0), fn(acc, block) {
            case acc, block {
                Empty2(_), Empty2(_) -> Empty2(0)
                Empty2(_), File2(len, id) -> {
                    case len <= want_len {
                        True -> File2(len, id)
                        False -> Empty2(0)
                    }
                }
                File2(len, id), _ -> File2(len, id)
            }
        })
    case match {
        Empty2(_) -> option.None
        File2(len, id) -> {
            let updated_memory = memory
                |> list.map(fn(x) {
                    // This relies on the fact that `id` is unique within the list
                    // so there will only be one overwrite.
                    case x == File2(len, id) {
                        True -> Empty2(len)
                        False -> x
                    }
                })
            option.Some(#(match, updated_memory))
        }
    }
}

pub fn part2(memory: List(Block2)) -> Int {
    memory
    // |> pretty_print2
    |> defragment2
    // |> pretty_print2
    |> list.map(fn(block) {
        case block {
            Empty2(len) -> list.repeat(0, len)
            File2(len, id) -> {
                let assert Ok(x) = int.parse(id)
                list.repeat(x, len)
            }
        }
    })
    |> list.flatten
    |> list.index_map(fn(block, idx) { idx * block })
    |> list.reduce(int.add)
    |> result.unwrap(0)
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day9.txt")
    let memory = parse1(contents)
    io.println("Part 1: " <> int.to_string(part1(memory)))
    let memory2 = parse2(contents)
    io.println("Part 2: " <> int.to_string(part2(memory2)))
}