defmodule Wordler.Sources.Oxford do
  @moduledoc """
  Relative letter frequency from Concise Oxford Dictionary analysis at https://www3.nd.edu/~busiforc/handouts/cryptography/letterfrequencies.html

  This is a naive approach to frequency-based guessing, because individual letter frequency isn't really what's relevant for Wordle.
  The more relevant measure is phoneme frequency for groups like "ea" and "ou" and "ai",
  and the number of words which contain each phoneme and can be eliminated by the absence of one of its constituent letters.

  So a guess like "adieu", though it has a lower frequency score than "irate", could more effectively reduce the search space.
  """

  @frequencies %{
    ?e => 5688,
    ?a => 4331,
    ?r => 3864,
    ?i => 3845,
    ?o => 3651,
    ?t => 3543,
    ?n => 3392,
    ?s => 2923,
    ?l => 2798,
    ?c => 2313,
    ?u => 1851,
    ?d => 1725,
    ?p => 1614,
    ?m => 1536,
    ?h => 1531,
    ?g => 1259,
    ?b => 1056,
    ?f => 924,
    ?y => 906,
    ?w => 657,
    ?k => 561,
    ?v => 513,
    ?x => 148,
    ?z => 139,
    ?j => 100,
    ?q => 100
  }

  @spec frequency_score(binary()) :: number
  def frequency_score(word) do
    for <<c <- word>>, reduce: 0 do
      acc -> acc + Map.get(@frequencies, c)
    end
  end
end
