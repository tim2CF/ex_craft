# ExCraft

Helper tool to define Elixir structures and constructors.

- Gives some compile-time control of types, required and default values.
- Generates constructor `&new/1` for your data structure.

# Usage

  Define your structures like a BOSS:

  ```
  defmodule ExCraft.Car do
    require ExCraft
    ExCraft.craft [
      %{name: :brand,  type: :string,        required: false,   default: "custom"},
      %{name: :year,   type: :pos_integer,   required: true,    default: nil},
      %{name: :used,   type: :boolean,       required: false,   default: true},
    ]
  end
  ```

# Examples

  Use structure as is, or use `&new/1` constructor to perform some
  implicit types conversions and checks. It's very useful
  in Phoenix plugs/controllers because request parameters are usually passed
  as maps with strings as keys and values.

  ```
  iex> alias ExCraft.Car
  ExCraft.Car
  iex> %Car{year: 1990}
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new(%{"year" => "1990"})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new(%{year: "1990"})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new([year: "1990"])
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new(%{"year" => 1990.0})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new(%{"year" => "1990.1"})
  ** (RuntimeError) Elixir.ExCraft.Car ExCraft error. Type of "1990.1" is not pos_integer. Error in field %ExCraft.Field{default: nil, name: :year, required: true, type: :pos_integer} of data source %{"year" => "1990.1"}.
  ```

# Types

  List of available types.

  ```
  :atom
  :binary
  :string
  :number
  :pos_number
  :non_neg_number
  :integer
  :pos_integer
  :non_neg_integer
  :float
  :pos_float
  :non_neg_float
  :struct
  :map
  :list
  :tuple
  :keyword
  :boolean
  ```
