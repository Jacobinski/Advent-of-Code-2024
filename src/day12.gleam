import gleam/dict
import gleam/int
import gleam/list
import gleam/io
import gleam/string
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
    io.println("Part 2: " <> int.to_string(part2(farm_map)))
}

pub fn part2(farm_map: FarmMap) -> Int {
    // This part can be solved by counting the verticies of the box
    // instead of measuring the number of continuous sides. This is
    // simple to wrap your head around theoretically (one side = one
    // vertex) but keeping track of it all is quite annoying.
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
        let farm_dict = region |> list.map(fn(p) { #(p.coordinate, p)}) |> dict.from_list
        let area = list.length(region)
        let assert Ok(sides) = {
            region
            |> list.fold(dict.new(), fn(verticies, plot) {
                let #(x, y) = plot.coordinate
                verticies
                |> dict.insert(#(x, y), vertex_count(farm_dict, #(x-1, y-1), #(x-1, y), #(x, y-1)))
                |> dict.insert(#(x+1, y), vertex_count(farm_dict, #(x+1, y-1), #(x, y-1), #(x+1, y)))
                |> dict.insert(#(x, y+1), vertex_count(farm_dict, #(x-1, y+1), #(x-1, y), #(x, y+1)))
                |> dict.insert(#(x+1, y+1), vertex_count(farm_dict, #(x+1, y+1), #(x+1, y), #(x, y+1)))
            })
            |> dict.values
            |> list.reduce(int.add)
        }
        acc + area * sides
    })
}

pub fn vertex_count(d: dict.Dict(Coordinate, Plot), diagonal: Coordinate, neighbor1: Coordinate, neighbor2: Coordinate) -> Int {
    let diagonal = dict.get(d, diagonal)
    let neighbor1 = dict.get(d, neighbor1)
    let neighbor2 = dict.get(d, neighbor2)
    case diagonal, neighbor1, neighbor2 {
        Ok(_), Ok(_), Ok(_) -> 0
        Error(_), Error(_), Ok(_) -> 0
        Error(_), Ok(_), Error(_) -> 0
        Ok(_), Error(_), Ok(_) -> 1
        Ok(_), Ok(_), Error(_) -> 1
        Error(_), Ok(_), Ok(_) -> 1
        Error(_), Error(_), Error(_) -> 1
        Ok(_), Error(_), Error(_) -> 2
    }
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
        True, _ -> region
        False, False -> region
        False, True -> {
            let #(x, y) = coordinate
            let neighbors = [
                is_correct_target(target, #(x+1, y), map),
                is_correct_target(target, #(x-1, y), map),
                is_correct_target(target, #(x, y+1), map),
                is_correct_target(target, #(x, y-1), map),
            ] |> list.count(fn(x) { x == True })

            // This weird structure ensures that we don't have an infinite loop.
            // Each iteration will return the original region, plus any newly
            // seen nodes. This is an alternative to the usual global seen map
            // used with more permissive languages.
            let region = [Plot(coordinate, neighbors, target), ..region]
            let region = search(target, #(x+1, y), region, map)
            let region = search(target, #(x-1, y), region, map)
            let region = search(target, #(x, y+1), region, map)
            let region = search(target, #(x, y-1), region, map)
            region
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

