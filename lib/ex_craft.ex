defmodule ExCraft do

  @types [
    :atom,
    :binary,
    :string,
    :number,
    :pos_number,
    :non_neg_number,
    :integer,
    :pos_integer,
    :non_neg_integer,
    :float,
    :pos_float,
    :non_neg_float,
    :struct,
    :map,
    :list,
    :tuple,
    :keyword,
    :boolean,
  ]

  @doc """
  Macro is expanded to structure definition and constructors

  ## Usage

  ```
  defmodule ExCraft.Car do
    import ExCraft
    craft [
      %ExCraft.Field{name: :brand,  type: :string,        required: false,   default: "custom",  enforce: false},
      %ExCraft.Field{name: :year,   type: :pos_integer,   required: true,    default: nil,       enforce: true},
      %ExCraft.Field{name: :used,   type: :boolean,       required: false,   default: true,      enforce: false},
    ]
  end
  ```

  ## Examples

  ```
  iex> alias ExCraft.Car
  ExCraft.Car
  iex> %Car{year: 1990}
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new!(%{"year" => "1990"})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new!(%{year: "1990"})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new!([year: "1990"])
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new!(%{"year" => 1990.0})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new!(%Car{brand: "custom", used: true, year: 1990})
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.new!(%{"year" => "1990.1"})
  ** (RuntimeError) Elixir.ExCraft.Car ExCraft error. Type of "1990.1" is not pos_integer. Error in field %ExCraft.Field{default: nil, enforce: true, name: :year, required: true, type: :pos_integer} of data source %{"year" => "1990.1"}.

  iex> require ExCraft.Car, as: Car
  ExCraft.Car
  iex> Car.struct!(year: 1990)
  %Car{brand: "custom", used: true, year: 1990}
  iex> struct = Car.struct!(year: 1990)
  %Car{brand: "custom", used: true, year: 1990}
  iex> Car.struct!(struct, brand: "Ford")
  %Car{brand: "Ford", used: true, year: 1990}
  iex> Car.struct!(struct, [])
  %Car{brand: "custom", used: true, year: 1990}
  ```
  """

  defmacro craft(quoted_fields = [_|_]) do

    {raw_fields = [%{}|_], []} =
      quoted_fields
      |> Code.eval_quoted

    decoded_fields =
      raw_fields
      |> Enum.map(&decode_field/1)

    fields_definitions =
      decoded_fields
      |> Enum.map(fn(%ExCraft.Field{name: name, default: default}) ->
        {name, default}
      end)

    enforce_keys =
      decoded_fields
      |> Stream.filter(fn(%ExCraft.Field{enforce: enforce}) -> enforce end)
      |> Enum.map(fn(%ExCraft.Field{name: name}) -> name end)

    quote do

      @enforce_keys unquote(enforce_keys)
      defstruct     unquote(fields_definitions |> Macro.escape)

      defmacro struct!(kv) do
        if not Keyword.keyword?(kv) do
          "#{__MODULE__} ExCraft error. Macro &struct!/1 can accept only keyword list."
          |> raise
        end

        module_ast = __MODULE__
        module_alias_ast =
          __MODULE__
          |> Module.split
          |> Enum.map(&String.to_atom/1)

        structure_ast = {:%, [],
          [
            {:__aliases__, [alias: false], module_alias_ast},
            {:%{}, [], kv}
          ]
        }

        quote do
          unquote(structure_ast)
          #
          # TODO : optimize it, not all code from new! is actually needed here
          #
          |> unquote(module_ast).new!
        end
      end

      defmacro struct!(code, kv) do
        if not Keyword.keyword?(kv) do
          "#{__MODULE__} ExCraft error. Macro &struct!/2 can accept only keyword list as 2nd argument."
          |> raise
        end

        module_ast = __MODULE__
        module_alias_ast =
          __MODULE__
          |> Module.split
          |> Enum.map(&String.to_atom/1)

        structure_ast =
          kv
          |> case do
            [] ->
              code
            [_ | _] ->
              {
                :%,
                [],
                [
                  {:__aliases__, [alias: false], module_alias_ast},
                  {:%{}, [], [{:|, [], [code, kv]}]}
                ]
              }
          end

        quote do
          unquote(structure_ast)
          #
          # TODO : optimize it, not all code from new! is actually needed here
          #
          |> unquote(module_ast).new!
        end
      end

      def new!(raw_data_source) do

        data_source = Aspire.to_map(raw_data_source)

        if not(is_map(data_source)) do
          "#{__MODULE__} ExCraft error. Data source #{inspect raw_data_source} can not be converted to map."
          |> raise
        end

        unquote(decoded_fields |> Macro.escape)
        |> Enum.reduce(%{}, fn(field = %ExCraft.Field{name: name, type: type, required: required, default: default}, acc = %{}) ->

            name_string = Atom.to_string(name)

            presented_in_data_source = Map.has_key?(data_source, name) or Map.has_key?(data_source, name_string)

            if required and not(presented_in_data_source) do
              "#{__MODULE__} ExCraft error. Required field #{inspect field} was not provided by data source #{inspect data_source}."
              |> raise
            end

            value = (Map.get(data_source, name) || Map.get(data_source, name_string))
                    |> case do
                      nil when presented_in_data_source -> nil
                      nil -> default
                      some when (type == :atom) ->
                        try do
                          some
                          |> Aspire.to_string
                          |> String.to_existing_atom
                        rescue
                          ArgumentError ->
                            "#{__MODULE__} ExCraft error. Atom with name #{inspect some} does not exist. Error in field #{inspect field} of data source #{inspect data_source}."
                            |> reraise(System.stacktrace)
                        end
                      some when (type in [:binary, :string]) ->
                        some |> Aspire.to_string
                      some when (type in [:number, :pos_number, :non_neg_number]) ->
                        some |> Aspire.to_number
                      some when (type in [:integer, :pos_integer, :non_neg_integer]) ->
                        some |> Aspire.to_integer
                      some when (type in [:float, :pos_float, :non_neg_float]) ->
                        some |> Aspire.to_float
                      some when (type == :struct) ->
                        some
                      some when (type == :map) ->
                        some |> Aspire.to_map
                      some when (type == :list) ->
                        some
                      some when (type == :tuple) ->
                        some
                      some when (type == :keyword) ->
                        some
                      some when (type == :boolean) ->
                        some |> Aspire.to_boolean
                    end

            if (value != nil) and not(value |> ExCraft.is_type(type)) do
              "#{__MODULE__} ExCraft error. Type of #{inspect value} is not #{type}. Error in field #{inspect field} of data source #{inspect data_source}."
              |> raise
            end

            Map.put(acc, name, value)

        end)
        |> Map.put(:__struct__, __MODULE__)
        |> validate!
      end

      def validate!(data = %__MODULE__{}) do
        data
      end
      def validate!(data) do
        "#{__MODULE__} ExCraft error. Data #{inspect data} is not a %#{__MODULE__}{}."
        |> raise
      end

      defoverridable [validate!: 1]
    end

  end

  @doc """
  Boolean function, checks type of first argument.

  ## Examples

  ```
  iex> ExCraft.is_type("hello", :string)
  true
  iex> ExCraft.is_type("hello", :binary)
  true
  iex> ExCraft.is_type(<<200, 200, 200>>, :string)
  false
  iex> ExCraft.is_type(<<200, 200, 200>>, :binary)
  true
  ```
  """
  def is_type(some, :atom) when is_atom(some), do: true
  def is_type(some, :binary) when is_binary(some), do: true
  def is_type(some, :string) when is_binary(some), do: String.valid?(some)
  def is_type(some, :number) when is_number(some), do: true
  def is_type(some, :pos_number) when is_number(some) and (some > 0), do: true
  def is_type(some, :non_neg_number) when is_number(some) and (some >= 0), do: true
  def is_type(some, :integer) when is_integer(some), do: true
  def is_type(some, :pos_integer) when is_integer(some) and (some > 0), do: true
  def is_type(some, :non_neg_integer) when is_integer(some) and (some >= 0), do: true
  def is_type(some, :float) when is_float(some), do: true
  def is_type(some, :pos_float) when is_float(some) and (some > 0), do: true
  def is_type(some, :non_neg_float) when is_float(some) and (some >= 0), do: true
  def is_type(%_{}, :struct), do: true
  def is_type(%_{}, :map), do: false
  def is_type(%{},  :map), do: true
  def is_type(some, :list) when is_list(some), do: true
  def is_type(some, :tuple) when is_tuple(some), do: true
  def is_type(some, :keyword) when is_list(some), do: Keyword.keyword?(some)
  def is_type(some, :boolean) when is_boolean(some), do: true
  def is_type(_, type) when (type in @types), do: false

  defp decode_field(field = %ExCraft.Field{name: name, type: type, required: required, default: default, enforce: enforce})
          when is_atom(name) and (type in @types) and is_boolean(required) and is_boolean(enforce) do

    if (default != nil) and required do
      "#{__MODULE__}. If field is required, default value can not be specified (default should be nil). Error in field #{inspect field}"
      |> raise
    end

    if (default != nil) and (not is_type(default, type)) do
      "#{__MODULE__}. Type of #{inspect default} is not #{type}. Error in field #{inspect field}"
      |> raise
    end

    %ExCraft.Field{
      name: name,
      type: type,
      required: required,
      default: default,
      enforce: enforce
    }
  end

end
