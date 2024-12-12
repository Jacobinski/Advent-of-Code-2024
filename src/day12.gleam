import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/string
import gleam/set
import simplifile as file

pub type Crop = String
pub type Coordinate = #(Int, Int)
pub type FarmMap = dict.Dict(Coordinate, Crop)

pub type Plot {
    Plot(coordinate: Coordinate, neighbors: Int, crop: Crop)
}

pub fn main() {
    let assert Ok(contents) = file.read("inputs/day12.txt")
    let farm_map = parse(contents)
    io.println("Part 1: " <> int.to_string(part1(farm_map)))
}

pub fn part1(farm_map: FarmMap) -> Int {
    let regions = {
        farm_map
        |> dict.to_list
        |> list.fold([], fn(regions, plot) {
            let #(coordinate, crop) = plot
            let all_plots_in_regions = list.flatten(regions)
            case is_visited(coordinate, all_plots_in_regions) {
                True -> regions
                False -> list.append(regions, [search(crop, coordinate, [], farm_map)])
            }
        })
    }
    regions
    |> list.fold(0, fn(acc, region) {
        let area = region |> list.length
        let perimeter = region |> list.fold(0, fn(acc, plot) { acc + {4 - plot.neighbors} })
        acc + area * perimeter
    })
}

pub fn is_correct_target(target: Crop, coordinate: Coordinate, map: FarmMap) -> Bool {
    case dict.get(map, coordinate) {
        Error(_) -> False
        Ok(crop) -> crop == target
    }
}

pub fn is_visited(coordinate: Coordinate, region: List(Plot)) -> Bool {
    case list.find(region, fn(plot) { plot.coordinate == coordinate }) {
        Ok(_) -> True
        Error(_) -> False
    }
}

pub fn search(target: Crop, coordinate: Coordinate, region: List(Plot), map: FarmMap) -> List(Plot) {
    let is_visited = is_visited(coordinate, region)
    let is_correct = is_correct_target(target, coordinate, map)
    case is_visited, is_correct {
        True, _ -> []
        False, False -> []
        False, True -> {
            let #(x, y) = coordinate
            let neighbors = [
                is_correct_target(target, #(x+1, y), map),
                is_correct_target(target, #(x-1, y), map),
                is_correct_target(target, #(x, y+1), map),
                is_correct_target(target, #(x, y-1), map),
            ] |> list.count(fn(x) { x == True })

            // This weird structure ensures that we don't have an infinite loop.
            // We depth-first-search in each direction, and maintain the list
            // pass along the list of known nodes with each iteration.
            // We DFS in each direction, save the
            let region = [Plot(coordinate, neighbors, target), ..region]
            let region = list.append(search(target, #(x+1, y), region, map), region)
            let region = list.append(search(target, #(x-1, y), region, map), region)
            let region = list.append(search(target, #(x, y+1), region, map), region)
            let region = list.append(search(target, #(x, y-1), region, map), region)
            // HACK: Deduplicate
            region
            |> set.from_list
            |> set.to_list
        }
    }
}

pub fn parse(contents: String) -> FarmMap {
    contents
    |> string.split("\n")
    |> list.index_map(fn(row, row_idx) {
        row
        |> string.to_graphemes
        |> list.index_map(fn(char, col_idx) {
            #(#(col_idx, row_idx), char)
        })
    })
    |> list.flatten
    |> dict.from_list
}

