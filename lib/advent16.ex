defmodule Advent16 do
  defp path(tail), do: Path.expand("data") |> Path.join(tail)
  def read!(file), do: path(file) |> File.read!
  def stream!(file), do: path(file) |> File.stream!

  defmodule Day1 do
    def part1 do
      {x, y, _} = Advent16.read!("16/1")
      |> String.split(", ")
      |> Enum.reduce({0, 0, 0}, &follow_instructions/2)

      abs(x) + abs(y)
    end

    def part2 do
      {x, y} = Advent16.read!("16/1")
      |> String.split(", ")
      |> Enum.reduce([{0, 0, 0}], &visited_locations/2)
      |> Enum.map(fn {x, y, _} -> {x, y} end)
      |> Enum.reverse
      |> find_first_duplicate(%{})

      abs(x) + abs(y)
    end

    def follow_instructions(instruction, {x, y, direction}) do
      distance = String.to_integer(String.slice(instruction, 1..-1))
      direction = case String.at(instruction, 0) do
        "L" -> rem(direction + 3, 4)
        "R" -> rem(direction + 1, 4)
      end
      
      {step_x, step_y} = case direction do
        0 -> {0, distance}
        1 -> {distance, 0}
        2 -> {0, -distance}
        3 -> {-distance, 0}
      end

      {x + step_x, y + step_y, direction}
    end

    defp visited_locations(instruction, [last_visited | visited]) do
      {last_x, last_y, _} = last_visited
      {next_x, next_y, next_direction} = follow_instructions(instruction, last_visited)
      
      next_visited = for x <- next_x..last_x, y <- next_y..last_y, do: {x, y, next_direction}
      next_visited ++ visited
    end

    defp find_first_duplicate([head | tail], set) do
      case set do
        %{^head => true} -> head
        %{} -> find_first_duplicate(tail, Map.put(set, head, true))
      end
    end
  end

  defmodule Day2 do
    def part1, do: main({0, 0}, fn {x, y} -> abs(x) <= 1 && abs(y) <= 1 end, fn {x, y} -> (1 - y) * 3 + x + 2 + ?0 end)
    def part2, do: main({-2, 0}, fn {x, y} -> abs(x) + abs(y) <= 2 end, fn {x, y} ->
      case y do
        2 -> ?1
        1 -> ?3 + x
        0 -> ?7 + x
        -1 -> ?B + x
        -2 -> ?D
      end
    end)

    defp main(start_position, valid?, convert_to_char) do
      Advent16.stream!("16/2")
      |> Enum.reduce([start_position], &decrypt_code(&1, &2, valid?))
      |> Enum.reverse
      |> Kernel.tl
      |> Enum.map(convert_to_char)
      |> Kernel.to_string
    end

    defp decrypt_code(code, [start_position | rest], valid?) do
      end_position = code
      |> String.replace("\n", "")
      |> String.codepoints
      |> Enum.reduce(start_position, &step(&1, &2, valid?))

      [end_position | [start_position | rest]]
    end

    defp step(char, {x, y}, valid?) do
      next = case char do
        "U" -> {x, y+1}
        "R" -> {x+1, y}
        "D" -> {x, y-1}
        "L" -> {x-1, y}
      end
      if valid?.(next), do: next, else: {x, y}
    end
  end

  defmodule Day3 do
    def part1(part2 \\ & &1) do
      Advent16.stream!("16/3")
      |> Stream.map(&Regex.scan(~r/(\d+)\s+(\d+)\s+(\d+)/, &1))
      |> Stream.map(fn [[_, x, y, z]] -> [String.to_integer(x), String.to_integer(y), String.to_integer(z)] end)
      |> part2.()
      |> Stream.map(&Enum.sort/1)
      |> Stream.filter(fn [x, y, z] -> x + y > z end)
      |> Enum.count
    end

    def part2, do: part1(&part2_rotate/1)

    defp part2_rotate(stream) do
      stream
      |> Stream.chunk_every(3)
      |> Stream.map(fn [[a,b,c], [d,e,f], [h,i,j]] -> [[a,d,h], [b,e,i], [c,f,j]] end)
      |> Enum.reduce(&Kernel.++/2)
    end
  end

  defmodule Day4 do
    defp main do
      Regex.scan(~r/(\S+)-(\d+)\[(\S+)\]/, Advent16.read!("16/4"))
      |> Enum.map(fn [_, text, id, checksum] -> {text, String.to_integer(id), checksum} end)
      |> Enum.filter(fn {text, _, checksum} -> checksum(text) == checksum end)
    end

    def part1 do
      main()
      |> Enum.map(fn {_, id, _} -> id end)
      |> Enum.sum
    end

    def part2 do
      main()
      |> Enum.map(&decrypt/1)
      |> Enum.filter(fn {text, _} -> String.contains?(text, "pole") end)
    end

    defp checksum(text) do
      letter_counts = text
      |> String.replace("-", "")
      |> String.codepoints
      |> Enum.reduce(%{}, fn letter, acc -> Map.update(acc, letter, 1, &(&1 + 1)) end)

      letter_counts
      |> Map.keys
      |> Enum.sort(&(letter_counts[&1] > letter_counts[&2] || (letter_counts[&1] == letter_counts[&2] && &1 < &2)))
      |> Enum.take(5)
      |> Enum.join
    end

    def decrypt({text, id, _}) do
      text = text
      |> String.to_charlist
      |> Enum.map(fn letter ->
        case letter do
          ?- -> 32
          other -> rem(other - ?a + id, 26) + ?a
        end
      end)
      |> to_string

      {text, id}
    end
  end
end