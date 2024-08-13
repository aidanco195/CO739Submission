import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic

open Topology Filter
open MeasureTheory

/-
The purpose of this project is to formalize some results about weak convergence of probability measures.
Let's start with a little bit of background. When working with metric spaces, it is common to consider
convergence within the metric space. It is also possible to consider the metric space as a measurable
space using the Borel σ-algebra, which is generated by the open sets. We can then discuss convergence
of measurable functions on the measurable space. In this project, we take this one step further, and
define convergence on the probability measures on the measurable space. We define a notion of convergence,
called weak convergence, as follows:
A sequence of measures (μ_n) is said to converge weakly to a measure μ if μ_n(S) converges to μ(S) for
all continuity sets S.
Note that a continuity set is a set whose boundary has no mass under μ, and when we say μ_n(S) converges
to μ(S) we mean using the standard topology on ℝ.
-/

-- We start with a Borel space, X, which is a metric space with the Borel σ-algebra
variable {X : Type*} [MetricSpace X] [MeasurableSpace X] [BorelSpace X] {S T : Set X} {μ ν : Measure X}

-- We formally define what we mean by continuity set: a set whose boundary has no mass under μ
def IsContinuitySet (μ : Measure X) (S : Set X) [IsProbabilityMeasure μ] := μ (frontier S) = 0

/-
We now use the properties of probability measures to prove some simple results about continuity sets
which will be useful later. Note that we use the first result to prove the next two, since the set lies
between its interior and closure.
-/

-- For a continuity set, the measure of its interior and closure coincide.
theorem meas_int_eq_meas_clos_of_cont_set [IsProbabilityMeasure μ] (h : IsContinuitySet μ S) :
    μ (interior S) = μ (closure S) := by
  rw [← add_zero (μ (interior S)), ← h, ← measure_union, closure_eq_interior_union_frontier]
  exact disjoint_interior_frontier
  exact isClosed_frontier.measurableSet

-- For a continuity set, the measure of the set and its interior coincide.
theorem meas_eq_meas_int_of_cont_set [IsProbabilityMeasure μ] (h : IsContinuitySet μ S) :
    μ S = μ (interior S) := by
  apply eq_of_le_of_le
  · rw [meas_int_eq_meas_clos_of_cont_set h]
    exact measure_mono subset_closure
  exact measure_mono interior_subset

-- For a continuity set, the measure of the set and its closure coincide.
theorem meas_eq_meas_clos_of_cont_set [IsProbabilityMeasure μ] (h : IsContinuitySet μ S) :
    μ S = μ (closure S) := by
  apply eq_of_le_of_le
  · exact measure_mono subset_closure
  rw [← meas_int_eq_meas_clos_of_cont_set h]
  exact measure_mono interior_subset

/-
A sequence of measures (μ_n) converges weakly to a measure μ if μ_n(S) converges to μ(S) for
all continuity sets S.
-/
def ConvergesWeakly (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :=
    ∀ S, IsContinuitySet μ S → Tendsto (fun x ↦ measureSeq x S) atTop (𝓝 (μ S))


/-
We give two definitions, which we will show to be equivalent, and that each is a sufficient
condition for weak convergence. They are as follows.
-/

-- A sequence of measures (μ_n) converges ro μ using liminfs if liminf(μ_n(S)) ≥ μ(S) for all open S.
def ConvergesUsingLiminf (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :=
    ∀ S, IsOpen S → μ S ≤ liminf (fun x ↦ measureSeq x S) atTop

-- A sequence of measures (μ_n) converges to μ using limsups if limsup(μ_n(S)) ≤ μ(S) for all closed S.
def ConvergesUsingLimsup (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :=
  ∀ S, IsClosed S → limsup (fun x ↦ measureSeq x S) atTop ≤ μ S

/-
We now prove that these two definitions are equivalent. The proofs of the two directions are similar.
-/

-- We prove that if (μ_n) converges to μ using liminfs, then (μ_n) converges to μ using limsups.
theorem converges_weakly_limsup_of_liminf (measureSeq : ℕ → Measure X) (μ : Measure X)
    [IsProbabilityMeasure μ] [∀x, IsProbabilityMeasure (measureSeq x)] :
    ConvergesUsingLiminf measureSeq μ → ConvergesUsingLimsup measureSeq μ := by

  -- We start with a closed set S.
  intro hLiminf S hS

  -- We give a short lemma, which follows directly from the additivity of measures
  -- and the fact that μ is a probability measure, μ(Sᶜ) = 1 - μ(S)
  have hSSc : μ Sᶜ = 1 - μ S := by
    exact prob_compl_eq_one_sub hS.measurableSet

  -- We have a similar lemma, but this time for the measures in the sequence.
  have hseqSSc : ∀ x, measureSeq x Sᶜ = 1 - measureSeq x S := by
    intro x
    apply prob_compl_eq_one_sub hS.measurableSet

  -- We apply convergence using liminfs to Sᶜ, which is open because S is closed.
  have hSc : μ Sᶜ ≤ liminf (fun x => measureSeq x Sᶜ ) atTop := by
    apply hLiminf
    exact hS.isOpen_compl
  simp_rw [hseqSSc] at hSc

  -- We now use properties of liminf and limsup, as well as the previous lemmas to rewrite the
  -- previous inequality into an inequality using S instead of Sᶜ , 1 - μ(S) ≤ 1 - limsup(mu_n(S))
  have hinfsup : liminf (fun x ↦ 1 - measureSeq x S) atTop = 1 - limsup (fun x ↦ measureSeq x S) atTop := by
    apply ENNReal.liminf_const_sub atTop
    exact ENNReal.one_ne_top
  rw [hinfsup, hSSc] at hSc

  /-
  We now are now almost done with the proof. We have that 1 - μ(S) ≤ 1 - limsup(mu_n(S)) and we
  need to prove that limsup(mu_n(S)) ≤ μ(S). This seems straightforward, but we have a few more
  details to work out because we are working with the extended real numbers.
  -/

  -- We give two lemmas, which follow from the fact that probability measures range from 0 and 1.
  -- The sequence of measures eventually gives mass to S between 0 and 1.
  have hleseq : ∀ᶠ x in atTop, 0 ≤ measureSeq x S:= by
    filter_upwards
    intro x
    exact zero_le (measureSeq x S)
  have hseqle : ∀ᶠ x in atTop, measureSeq x S ≤ 1 := by
    filter_upwards
    intro x
    exact prob_le_one

  -- We now have everything we need to complete the proof.
  rw [← ENNReal.sub_le_sub_iff_left]
  · exact hSc
  · apply limsup_le_of_le
    apply isCoboundedUnder_le_of_eventually_le atTop
    · exact hleseq
    exact hseqle
  exact ENNReal.one_ne_top

-- We prove that if (μ_n) converges to μ using limisups, then (μ_n) converges to μ using liminfs.
theorem converges_weakly_liminf_of_limsup (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :
    ConvergesUsingLimsup measureSeq μ → ConvergesUsingLiminf measureSeq μ := by

  -- We start with an open set S.
  intro hLimsup S hS

  -- We give a short lemma, which follows directly from the additivity of measures
  -- and the fact that μ is a probability measure, μ(Sᶜ) = 1 - μ(S)
  have hSSc : μ Sᶜ = 1 - μ S := by
    exact prob_compl_eq_one_sub hS.measurableSet

  -- We have a similar lemma, but this time for the measures in the sequence.
  have hseqSSc : ∀ x, measureSeq x Sᶜ = 1 - measureSeq x S := by
    intro x
    apply prob_compl_eq_one_sub hS.measurableSet

  -- We apply convergence using limsups to Sᶜ, which is closed because S is open.
  have hSc : limsup (fun x => measureSeq x Sᶜ ) atTop ≤ μ Sᶜ  := by
    apply hLimsup
    exact hS.isClosed_compl
  simp_rw [hseqSSc] at hSc

  -- We now use properties of liminf and limsup, as well as the previous lemmas to rewrite the
  -- previous inequality into an inequality using S instead of Sᶜ, 1 - liminf(mu_n(S)) ≤  1 - μ(S)
  have hsupinf : limsup (fun x ↦ 1 - measureSeq x S) atTop = 1 - liminf (fun x ↦ measureSeq x S) atTop := by
    apply ENNReal.limsup_const_sub atTop
    exact ENNReal.one_ne_top
  rw [hsupinf, hSSc] at hSc

  -- We now have everything we need to complete the proof. Note that we don't need the same lemmas
  -- as in the previous direction because we only need to show that μ(S) is bounded.
  rw [← ENNReal.sub_le_sub_iff_left]
  · exact hSc
  · exact prob_le_one
  exact ENNReal.one_ne_top

/-
We now combine the previous two results into an equivalence. That is, (μ_n) converges to μ using
liminfs if and only if (μ_n) converges to μ using limsups.
-/
theorem converges_weakly_limsup_iff_liminf (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :
    ConvergesUsingLiminf measureSeq μ ↔ ConvergesUsingLimsup measureSeq μ := by
  constructor
  exact converges_weakly_limsup_of_liminf measureSeq μ
  exact converges_weakly_liminf_of_limsup measureSeq μ

/-
Now that we have proved that convergence using liminfs and limsups are equivalent, we are ready to
prove that each of them is a sufficient condition for weak convergence. Note that although we only
need one of convergence using liminfs or limsups, we use both in the proof, which is why our previous
result was necessary.
-/

-- We prove that if (μ_n) converges to μ using liminfs, then (μ_n) converges weakly to μ.
theorem converges_weakly_of_liminf (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :
    ConvergesUsingLiminf measureSeq μ → ConvergesWeakly measureSeq μ := by

  -- We start with a continuity set S. Recall that this means S has no mass under μ.
  intro hLiminf S hS

  -- We also have convergence using limsups from the previous results.
  have hLimsup : ConvergesUsingLimsup measureSeq μ := by
    exact converges_weakly_limsup_of_liminf measureSeq μ hLiminf

  -- We have two lemmas, which follow from the fact that probability measures range from 0 and 1.
  -- The sequence of measures eventually gives mass to S between 0 and 1.
  have hseqle : ∀ᶠ x in atTop, measureSeq x S ≤ 1:= by
    filter_upwards
    intro x
    exact prob_le_one
  have hleseq : ∀ᶠ x in atTop, 0 ≤ measureSeq x S:= by
    filter_upwards
    intro x
    exact zero_le (measureSeq x S)

  /-
  We now prove two important facts. They are as follows:
  μ(int(S)) ≤ liminf(μ_n(S))
  limsup(μ_n(S)) ≤ μ(cl(S))
  where int(S) is the interior of S and cl(S) is the closure of S.
  -/

  -- We give a lemma which says that eventually μ_n(int(S)) ≤ μ_n(S). We use the fact that
  -- measures are monotone and that the interior of a set is a subset of the set itself.
  have hseqInt : ∀ᶠ x in atTop, measureSeq x (interior S) ≤ measureSeq x S := by
    filter_upwards
    intro x
    exact measure_mono interior_subset

  -- We use properties of liminf and the previous lemma to get that liminf(μ_n(int(S))) ≤ liminf(μ_n(S)).
  -- Once again we have to show boundedness because we are in the extended real numbers.
  have hseqLiminfInt : liminf (fun x ↦ measureSeq x (interior S)) atTop ≤ liminf (fun x ↦ measureSeq x S) atTop := by
    apply liminf_le_liminf
    · exact hseqInt
    · apply isBoundedUnder_of
      use 0
      intro x
      exact zero_le (measureSeq x (interior S))
    apply isCoboundedUnder_ge_of_eventually_le
    exact hseqle

  -- We get out desired fact, μ(int(S)) ≤ liminf(μ_n(int(S))) ≤ liminf(μ_n(S)) by applying transitivity to the
  -- previous result and convergence using liminfs, which we can do because the interior is open.
  have hLiminfInt : μ (interior S) ≤ liminf (fun x ↦ measureSeq x S) atTop := by
    apply le_trans _ hseqLiminfInt
    apply hLiminf
    exact isOpen_interior

  -- We give a lemma which says that eventually μ_n(S) ≤ μ_n(cl(S)). We use the fact that
  -- measures are monotone and that  a set is a subset of its closure.
  have hseqClos : ∀ᶠ x in atTop, measureSeq x S ≤ measureSeq x (closure S) := by
    filter_upwards
    intro x
    exact measure_mono subset_closure

  -- We use properties of limsup and the previous lemma to get that limsup(μ_n(S)) ≤ limsup(μ_n(cl(S))).
  -- Once again we have to show boundedness because we are in the extended real numbers.
  have hseqLimsupClos : limsup (fun x ↦ measureSeq x S) atTop ≤ limsup (fun x ↦ measureSeq x (closure S)) atTop := by
    apply limsup_le_limsup
    · exact hseqClos
    · apply isCoboundedUnder_le_of_eventually_le atTop
      exact hleseq
    apply isBoundedUnder_of
    use 1
    intro x
    exact prob_le_one

  -- We get out desired fact, limsup(μ_n(S)) ≤ limsup(μ_n(cl(S))) ≤ μ(cl(S)) by applying transitivity to the
  -- previous result and convergence using closure, which we can do because the closure is closed.
  have hLimsupClos : limsup (fun x ↦ measureSeq x S) atTop ≤ μ (closure S) := by
    apply le_trans hseqLimsupClos
    apply hLimsup
    exact isClosed_closure

  /-
  We are now have everything we need to complete the proof.
  We will need to apply our lemmas about continuity sets when we first defined them.
  These lemmas give us that μ(int(S)) = μ(S) = μ(cl(S)) because S is a set of continuity.
  Then we have limsup(μ_n(S)) ≤ μ(cl(S)) = μ(S) = μ(int(S)) ≤ liminf(μ_n(S))
  But we also have liminf(μ_n(S)) ≤ limsup(μ_n(S)) from properties of liminf and limsup.
  Then liminf(μ_n(S)) = limsup(μ_n(S)) = μ(S), which gives us convergence to μ(S).
  After showing boundedness again, we are done.
  -/
  apply tendsto_of_le_liminf_of_limsup_le
  · rw [meas_eq_meas_int_of_cont_set hS]
    exact hLiminfInt
  · rw [meas_eq_meas_clos_of_cont_set hS]
    exact hLimsupClos
  · apply isBoundedUnder_of
    use 1
    intro x
    exact prob_le_one
  apply isBoundedUnder_of
  use 0
  intro x
  exact zero_le (measureSeq x S)

/-
We finally prove that if (μ_n) converges to μ using limsups, then (μ_n) converges weakly to μ.
This is just a simple combination of our previous two results. Recall that they were:
If (μ_n) converges to μ using liminfs, then (μ_n) converges weakly to μ.
(μ_n) converges to μ using liminfs if and only if (μ_n) converges to μ using limsups.
-/
theorem converges_weakly_of_limsup (measureSeq : ℕ → Measure X) (μ : Measure X)
    [∀x, IsProbabilityMeasure (measureSeq x)] [IsProbabilityMeasure μ] :
    ConvergesUsingLimsup measureSeq μ → ConvergesWeakly measureSeq μ := by
  intro hLimsup
  have hLiminf : ConvergesUsingLiminf measureSeq μ := by
    exact converges_weakly_liminf_of_limsup measureSeq μ hLimsup
  exact converges_weakly_of_liminf measureSeq μ hLiminf
