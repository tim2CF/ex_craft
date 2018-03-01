defmodule ExCraft do

  alias ExCraft.Field

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
  ]

  @doc """

  Macro is expanded to structure definition and constructor.

  ## Examples

      iex> %ExCraft.Test{atom: :erlang}
      %ExCraft.Test{
        atom: :erlang,
        binary: "hello",
        float: nil,
        integer: nil,
        keyword: nil,
        list: nil,
        map: nil,
        non_neg_float: nil,
        non_neg_integer: nil,
        non_neg_number: nil,
        number: nil,
        pos_float: nil,
        pos_integer: nil,
        pos_number: nil,
        string: "world",
        struct: nil,
        tuple: nil
      }
      iex> ExCraft.Test.new(%{"atom" => "erlang"})
      %ExCraft.Test{
        atom: :erlang,
        binary: "hello",
        float: nil,
        integer: nil,
        keyword: nil,
        list: nil,
        map: nil,
        non_neg_float: nil,
        non_neg_integer: nil,
        non_neg_number: nil,
        number: nil,
        pos_float: nil,
        pos_integer: nil,
        pos_number: nil,
        string: "world",
        struct: nil,
        tuple: nil
      }
      iex> ExCraft.Test.new(%{"atom" => "whoa!!!"})
      ** (RuntimeError) Elixir.ExCraft.Test ExCraft error. Atom with name "whoa!!!" does not exist. Error in field %ExCraft.Field{default: nil, name: :atom, required: true, type: :atom} of data source %{"atom" => "whoa!!!"}.
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
      |> Enum.map(fn(%Field{name: name, default: default}) ->
        {name, default}
      end)

    enforce_keys =
      decoded_fields
      |> Stream.filter(fn(%Field{required: required}) -> required end)
      |> Enum.map(fn(%Field{name: name}) -> name end)

    quote do

      @enforce_keys unquote(enforce_keys)
      defstruct     unquote(fields_definitions)

      def new(raw_data_source) do

        data_source = Maybe.to_map(raw_data_source)

        if not(is_map(data_source)) do
          "#{__MODULE__} ExCraft error. Data source #{inspect raw_data_source} can not be converted to map."
          |> raise
        end

        unquote(decoded_fields |> Macro.escape)
        |> Enum.reduce(%{}, fn(field = %ExCraft.Field{name: name, type: type, required: required, default: default}, acc = %{}) ->

            name_string = Atom.to_string(name)

            if required and not(Map.has_key?(data_source, name)) and not(Map.has_key?(data_source, name_string)) do
              "#{__MODULE__} ExCraft error. Required field #{inspect field} was not provided by data source #{inspect data_source}."
              |> raise
            end

            value = (Map.get(data_source, name) || Map.get(data_source, name_string) || default)
                    |> case do
                      nil -> nil
                      some when (type == :atom) ->
                        try do
                          some
                          |> Maybe.maybe_to_string
                          |> String.to_existing_atom
                        rescue
                          ArgumentError ->
                            "#{__MODULE__} ExCraft error. Atom with name #{inspect some} does not exist. Error in field #{inspect field} of data source #{inspect data_source}."
                            |> reraise(System.stacktrace)
                        end
                      some when (type in [:binary, :string]) ->
                        some |> Maybe.maybe_to_string
                      some when (type in [:number, :pos_number, :non_neg_number]) ->
                        some |> Maybe.to_number
                      some when (type in [:integer, :pos_integer, :non_neg_integer]) ->
                        some |> Maybe.to_integer
                      some when (type in [:float, :pos_float, :non_neg_float]) ->
                        some |> Maybe.to_float
                      some when (type == :struct) ->
                        some
                      some when (type == :map) ->
                        some |> Maybe.to_map
                      some when (type == :list) ->
                        some
                      some when (type == :tuple) ->
                        some
                      some when (type == :keyword) ->
                        some
                    end

            if (value != nil) and not(value |> is_type(type)) do
              "#{__MODULE__} ExCraft error. Type of #{inspect value} is not #{type}. Error in field #{inspect field} of data source #{inspect data_source}."
              |> raise
            end

            Map.put(acc, name, value)

        end)
        |> Map.put(:__struct__, __MODULE__)
      end

    end

  end

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
  def is_type(_, type) when (type in @types), do: false

  defp decode_field(field = %{name: name, type: type, required: required, default: default})
          when is_atom(name) and (type in @types) and is_boolean(required) do

    if (default != nil) and required do
      "#{__MODULE__}. If field is required, default value can not be specified (default should be nil). Error in field #{inspect field}"
      |> raise
    end

    if (default != nil) and (not is_type(default, type)) do
      "#{__MODULE__}. Type of #{inspect default} is not #{type}. Error in field #{inspect field}"
      |> raise
    end

    %Field{
      name: name,
      type: type,
      required: required,
      default: default
    }
  end

end
