defmodule Wordler.Sources.WordBank do
  @moduledoc """
  Letter frequency count of words from Wordle's client-side answer bank.
  """

  @frequencies %{
    97 => 979,
    98 => 281,
    99 => 477,
    100 => 393,
    101 => 1233,
    102 => 230,
    103 => 311,
    104 => 389,
    105 => 671,
    106 => 27,
    107 => 210,
    108 => 719,
    109 => 316,
    110 => 575,
    111 => 754,
    112 => 367,
    113 => 29,
    114 => 899,
    115 => 669,
    116 => 729,
    117 => 467,
    118 => 153,
    119 => 195,
    120 => 37,
    121 => 425,
    122 => 40
  }

  @spec generate_frequencies :: map
  def generate_frequencies() do
    File.stream!(File.cwd!() <> "/priv/static/wordle.txt")
    |> Stream.map(&String.trim/1)
    |> Stream.flat_map(&String.to_charlist/1)
    |> Enum.frequencies()
  end

  @spec frequency_score(binary()) :: number
  def frequency_score(word) do
    for <<c <- word>>, reduce: 0 do
      acc -> acc + Map.get(@frequencies, c)
    end
  end
end
