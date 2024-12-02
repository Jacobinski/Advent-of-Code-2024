import gleam/result
import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import gleam/io
import simplifile as file

type Report = List(Int)

pub fn main() {
  let assert Ok(contents) = file.read("inputs/day2.txt")
  let reports = parse(contents)
  io.println("Part 1: " <> int.to_string(part1(reports)))
  io.println("Part 2: " <> int.to_string(part2(reports)))
}

fn parse(content: String) -> List(Report) {
    content
    |> string.split("\n")
    |> list.map(fn(line){
        line
        |> string.split(" ")
        |> list.map(fn(x) {
            let assert Ok(x) = int.parse(x)
            x
        })
    })
}

fn part1(reports: List(Report)) -> Int {
    reports
    |> list.map(fn(report) {
        {increasing(report) || decreasing(report)} && bound_change(report)
    })
    |> list.count(fn(x) {x == True})
}

fn part2(reports: List(Report)) -> Int {
    // Part 2 allows for one bad event to be "skipped" per report list.
    // This is equivalent to generating a new report list with one skipped event.
    // Generate all combinations of lists missing one event, and check if any are ok.
    reports
    |> list.map(fn(report) {
        report
        |> list.combinations(list.length(report) - 1)
        // Run the part 1 logic on each generated combination
        |> list.map(fn(combo) {
            {increasing(combo) || decreasing(combo)} && bound_change(combo)
        })
        // Check if any combination was successful
        |> list.reduce(bool.or)
        |> result.unwrap(False)
    })
    |> list.count(fn(x) { x == True })
}

fn increasing(report: Report) -> Bool {
    report_check(report, fn(prev, curr) { curr > prev })
}

fn decreasing(report: Report) -> Bool {
    report_check(report, fn(prev, curr) { curr < prev })
}

fn bound_change(report: Report) -> Bool {
    report_check(report, fn(prev, curr) {
        int.absolute_value(curr - prev) >= 1 && int.absolute_value(curr - prev) <= 3
    })
}

fn report_check(report: Report, cmp: fn(Int, Int) -> Bool) -> Bool {
    let assert [first, ..rest] = report
    let res = list.fold(rest, #(True, first), fn(tuple, curr){
        let #(acc, prev) = tuple
        #(acc && cmp(prev, curr), curr)
    })
    res.0
}