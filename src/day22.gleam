import gleam/dict
import gleam/set
import gleam/pair
import gleam/string
import gleam/io
import gleam/option
import gleam/int
import gleam/list
import simplifile as file

const infinity = 999999999999999999
const negative_infinity = -999999999999999

pub type Price {
    Price(price: Int, delta: Int, sequence: List(Int) )
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day22.txt")
    let numbers = parse(contents)

    io.println("Part 1: " <> int.to_string(part1(numbers)))
    io.println("Part 2: " <> int.to_string(part2(numbers)))
}

pub fn part1(numbers: List(Int)) -> Int {
    numbers
    |> list.map(secret(_, 2000))
    |> list.fold(0, int.add)
}

pub fn part2(numbers: List(Int)) -> Int {
    let vendor_prices = list.map(numbers, create_prices)
    let vendor_price_dicts = vendor_prices
        |> list.map(fn(price) {
            price
            |> list.drop(4) // First four sequences are too short to be valid
            |> list.map(fn(p) { #(p.sequence, p.price)})
            // Reverse the list of tuples so that when dict.from_list() is
            // called, the first instance of the sequence is what will be
            // chosen over the next instances.
            |> list.reverse
            |> dict.from_list
        })
    let valid_sequences = vendor_price_dicts
        |> list.map(dict.keys)
        |> list.map(set.from_list)
        |> list.fold(set.new(), set.union)
        |> set.to_list

    valid_sequences
    |> list.map(fn(vs) {
        vendor_price_dicts
        |> list.filter_map(fn(vpd) { dict.get(vpd, vs) })
        |> list.fold(0, int.add)
    })
    |> list.fold(negative_infinity, int.max)
}

pub fn match_first(sequence: List(Int), prices: List(Price)) -> Int {
    let match = list.fold(prices, option.None, fn(saved, price) {
        case saved {
            option.Some(_) -> saved
            option.None -> case price.sequence == sequence {
                True -> option.Some(price.price)
                False -> option.None
            }
        }
    })
    case match {
        option.Some(x) -> x
        option.None -> 0
    }
}

pub fn create_prices(initial: Int) -> List(Price) {
    let prices = prices(initial, 2000, [])
    let deltas = deltas(prices)
    let sequences = sequences(deltas)

    // Padding to ensure all are 2000 long
    // let impossible_sequence = [infinity, infinity, infinity, infinity]
    let deltas = [infinity, ..deltas]
    let sequences = [[], [], [], [], ..sequences]

    list.zip(prices, list.zip(deltas, sequences))
    |> list.map(fn(tup) {
        let #(price, #(delta, sequence)) = tup
        Price(price, delta, sequence)
    })
}

pub fn sequences(deltas: List(Int)) -> List(List(Int)) {
    list.window(deltas, 4)
}

pub fn deltas(prices: List(Int)) -> List(Int) {
    let assert Ok(first) = list.first(prices)
    let assert Ok(rest) = list.rest(prices)

    list.fold(rest, #(first, []), fn(acc, price) {
        let #(prev, reverse_deltas) = acc
        #(price, [price-prev, ..reverse_deltas])
    })
    |> pair.second
    |> list.reverse
}

pub fn prices(initial: Int, repeats: Int, reverse_acc: List(Int)) -> List(Int) {
    case repeats {
        x if x <= 0 -> list.reverse(reverse_acc)
        _ -> {
            prices(
                next(initial),
                repeats - 1,
                [initial % 10, ..reverse_acc]
            )
        }
    }
}

pub fn secret(initial: Int, repeats: Int) -> Int {
    case repeats {
        x if x <= 0 -> initial
        _ -> secret(next(initial), repeats-1)
    }
}

pub fn next(secret: Int) -> Int {
    let secret = mix(secret * 64, secret) |> prune
    let secret = mix(secret / 32, secret) |> prune
    let secret = mix(secret * 2048, secret) |> prune
    secret
}

pub fn mix(number: Int, secret: Int) -> Int {
    int.bitwise_exclusive_or(number, secret)
}

pub fn prune(secret: Int) -> Int {
    secret % 16777216
}

pub fn parse(contents: String) -> List(Int) {
    contents
    |> string.split("\n")
    |> list.map(fn(x){
        let assert Ok(x) = int.parse(x)
        x
    })
}