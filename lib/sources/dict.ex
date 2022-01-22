defmodule Wordler.Sources.Dict do
  @moduledoc """
  American English source words from /usr/share/dict
  """

  @default_duplicates false

  @spec five_letter_words([keyword]) :: [binary()]
  def five_letter_words(options \\ []) do
    if Keyword.get(options, :duplicates, @default_duplicates) do
      all_five_letter_words()
      |> Enum.to_list()
    else
      all_five_letter_words()
      |> Stream.reject(&has_dupes?/1)
      |> Enum.to_list()
    end
  end

  @spec all_five_letter_words :: Stream.t()
  defp all_five_letter_words() do
    File.stream!(File.cwd!() <> "/priv/static/american-english")
    |> Stream.map(&String.trim/1)
    |> Stream.filter(&is_five_letters?/1)
    |> Stream.reject(&is_proper?/1)
    |> Stream.map(&String.downcase/1)
    |> Stream.filter(&is_ascii?/1)
  end

  defp is_five_letters?(<<_input::size(5)-bytes>>), do: true

  defp is_five_letters?(_bin), do: false

  defp is_ascii?(input) do
    (for <<c <- input>>, do: c in 97..122)
    |> Enum.all?()
  end

  defp is_proper?(<<first, _rest::binary>>), do: first not in 97..122

  defp has_dupes?(input) do
    5 != input
    |> String.to_charlist()
    |> Enum.uniq()
    |> length()
  end
end
