# Benchmark on non-weighted sampling 

# require the BenchmarkLite package
using BenchmarkLite
using StatsBase

import StatsBase: direct_sample!, xmultinom_sample!
import StatsBase: knuths_sample!, fisher_yates_sample!, self_avoid_sample!
import StatsBase: seqsample_a!, seqsample_c!

### generic sampling benchmarking

type SampleProc{Alg} <: Proc end

abstract WithRep 
abstract NoRep

type Direct <: WithRep end
tsample!(s::Direct, a, x) = direct_sample!(a, x)

type Xmultinom <: WithRep end
tsample!(s::Xmultinom, a, x) = xmultinom_sample!(a, x)

type Sample_WRep <: WithRep end
tsample!(s::Sample_WRep, a, x) = sample!(a, x; replace=true, ordered=false)

type Sample_WRep_Ord <: WithRep end
tsample!(s::Sample_WRep_Ord, a, x) = sample!(a, x; replace=true, ordered=true)

type Knuths <: NoRep end
tsample!(s::Knuths, a, x) = knuths_sample!(a, x)

type Fisher_Yates <: NoRep end
tsample!(s::Fisher_Yates, a, x) = fisher_yates_sample!(a, x)

type Self_Avoid <: NoRep end
tsample!(s::Self_Avoid, a, x) = self_avoid_sample!(a, x)

type Seq_A <: NoRep end
tsample!(s::Seq_A, a, x) = seqsample_a!(a, x)

type Seq_C <: NoRep end
tsample!(s::Seq_C, a, x) = seqsample_c!(a, x)

type Sample_NoRep <: NoRep end
tsample!(s::Sample_NoRep, a, x) = sample!(a, x; replace=false, ordered=false)

type Sample_NoRep_Ord <: NoRep end
tsample!(s::Sample_NoRep_Ord, a, x) = sample!(a, x; replace=false, ordered=true)


# config is in the form of (n, k)

Base.string{Alg}(p::SampleProc{Alg}) = lowercase(string(Alg))

Base.length(p::SampleProc, cfg::(Int, Int)) = cfg[2]
Base.isvalid{Alg<:WithRep}(p::SampleProc{Alg}, cfg::(Int, Int)) = ((n, k) = cfg; n >= 1 && k >= 1)
Base.isvalid{Alg<:NoRep}(p::SampleProc{Alg}, cfg::(Int, Int)) = ((n, k) = cfg; n >= k >= 1)

Base.start(p::SampleProc, cfg::(Int, Int)) = Array(Int, cfg[2])
Base.run{Alg}(p::SampleProc{Alg}, cfg::(Int, Int), s::Vector{Int}) = tsample!(Alg(), 1:cfg[1], s)
Base.done(p::SampleProc, cfg, s) = nothing


### benchmarking

const ns = 5 * (2 .^ [0:9])
const ks = 2 .^ [1:16]

## with replacement

const procs1 = Proc[ SampleProc{Direct}(), 
                     SampleProc{Sample_WRep}(),
                     SampleProc{Xmultinom}(), 
                     SampleProc{Sample_WRep_Ord}() ]

const cfgs1 = vec([(n, k) for k in ks, n in ns])

rtable1 = run(procs1, cfgs1; duration=0.2)
println()

## without replacement

const procs2 = Proc[ SampleProc{Knuths}(), 
                     SampleProc{Fisher_Yates}(),
                     SampleProc{Self_Avoid}(),
                     SampleProc{Sample_NoRep}(),
                     SampleProc{Seq_A}(),
                     SampleProc{Seq_C}(),
                     SampleProc{Sample_NoRep_Ord}() ]

const cfgs2 = (Int, Int)[]
for n in 5 * (2 .^ [0:11]), k in 2 .^ [1:16]
    if k < n
        push!(cfgs2, (n, k))
    end
end

rtable2 = run(procs2, cfgs2; duration=0.2)
println()

## show results

println("Sampling With Replacement")
println("===================================")
show(rtable1; unit=:mps, cfghead="(n, k)")
println()

println("Sampling Without Replacement")
println("===================================")
show(rtable2; unit=:mps, cfghead="(n, k)")
println()

