import gleam/result
import gleam/option
import gleam/int
import gleam/regexp
import gleam/io
import gleam/list
import simplifile as file

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day3.txt")
    io.println("Part 1: " <> int.to_string(part1(contents)))
    io.println("Part 2: " <> int.to_string(part2(contents)))
}

fn part1(contents: String) -> Int{
    let assert Ok(re) = regexp.compile(
        "mul\\((\\d{1,3}),(\\d{1,3})\\)",
        regexp.Options(
            case_insensitive: False,
            multi_line: True,
        )
    )
    regexp.scan(with: re, content: contents)
    |> list.map(fn(match){
        let assert [option.Some(x), option.Some(y)] = match.submatches
        let assert Ok(x) = int.parse(x)
        let assert Ok(y) = int.parse(y)
        x * y
    })
    |> list.reduce(int.add)
    |> result.unwrap(0)
}

const re_mul = "mul\\((\\d{1,3}),(\\d{1,3})\\)"
const re_do = "do\\(\\)"
const re_dont = "don't\\(\\)"

type Node {
    Mul(left: Int, right: Int)
    Do()
    Dont()
}

fn to_mul(string: String) -> option.Option(Node) {
    to_node(string, re_mul, fn(match) {
        let assert [option.Some(x), option.Some(y)] = match.submatches
        let assert Ok(x) = int.parse(x)
        let assert Ok(y) = int.parse(y)
        option.Some(Mul(x, y))
    })
}

fn to_do(string: String) -> option.Option(Node) {
    to_node(string, re_do, fn(_) {option.Some(Do)})
}

fn to_dont(string: String) -> option.Option(Node) {
    to_node(string, re_dont, fn(_) {option.Some(Dont)})
}

fn to_node(string: String, re: String, convert: fn(regexp.Match) -> option.Option(Node)) -> option.Option(Node) {
    let assert Ok(re) = regexp.from_string(re)
    case regexp.scan(with: re, content: string) {
        [match] -> convert(match)
        [] -> option.None
        _ -> option.None  // Impossible (?)
    }
}

fn classify(string: String) -> Node {
    let options = [ to_mul(string), to_do(string), to_dont(string) ]
    let assert option.Some(result) = list.fold(options, option.None, option.or)
    result
}

fn part2(contents: String) -> Int {
    let assert Ok(re) = regexp.compile(
        "(" <> re_mul <> "|" <> re_do <> "|" <> re_dont <> ")",
        regexp.Options(
            case_insensitive: False,
            multi_line: True,
        )
    )
    let result = regexp.scan(with: re, content: contents)
    |> list.map(fn(match) {classify(match.content)})
    |> list.fold(#(0, True), fn(state, node) {
        let #(sum, enabled) = state
        case node, enabled {
            Do, _ -> #(sum, True)
            Dont, _ -> #(sum, False)
            Mul(_,_), False -> #(sum, False)
            Mul(_,_), True -> #(sum+node.left*node.right, True)
        }
    })
    result.0
}
