import gleam/result
import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/string
import gleam/option
import simplifile as file

pub type Stone = Int
pub type Repeats = Int
pub type StoneDict = dict.Dict(Stone, Repeats)

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day11.txt")
    let stones = parse(contents)
    io.println("Part 1: " <> int.to_string(solution(stones, 25)))
    io.println("Part 2: " <> int.to_string(solution(stones, 75)))
}

pub fn solution(stones: StoneDict, times: Int) -> Int {
    blink(stones, times)
    |> dict.values
    |> list.reduce(int.add)
    |> result.unwrap(0)
}

pub fn blink(stones: StoneDict, times: Int) -> StoneDict {
    case times {
        x if x <= 0 -> stones
        _ -> {
            stones
            |> dict.to_list
            |> list.map(fn(stone_tuple) {
                let #(stone, repeats) = stone_tuple

                let assert Ok(digits) = int.digits(stone, 10)
                let len = list.length(digits)

                let is_zero = {0 == stone}
                let is_len_mod_2 = len % 2 == 0

                case is_zero, is_len_mod_2 {
                    True, _ -> [#(1, repeats)]
                    False, False -> [#(2024 * stone, repeats)]
                    False, True -> {
                        let #(first, second) = list.split(digits, len / 2)
                        [first, second]
                        |> list.map(fn(x) {
                            let assert Ok(x) = int.undigits(x, 10)
                            #(x, repeats)
                        })
                    }
                }
            })
            |> list.flatten
            |> list.fold(dict.new(), fn(acc, tup) {
                let #(stone, repeats) = tup
                dict.upsert(acc, stone, fn(x) {
                    case x {
                        option.Some(i) -> i + repeats
                        option.None -> repeats
                    }
                })
            })
            |> blink(times - 1)
        }
    }
}

pub fn parse(contents: String) -> StoneDict {
    contents
    |> string.split(" ")
    |> list.map(fn(x){
        let assert Ok(x) = int.parse(x)
        #(x, 1)
    })
    // ASSUMPTION: Each initial key is unique.
    |> dict.from_list
}