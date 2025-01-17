using EffectiveWaves, Test
using LinearAlgebra


# NOTE: at the moment there is no automated way to generate different pair-correlations, except for hole correction. For now, we assume data for the 2D pair-correlation is provided. For 3D there is a method to produce the Percus-Yevick pair correlation.


@testset "2D pair-correlation" begin

    # assume data is given for pair correlation
    r = 1.0
    rs = (2r):0.1:(4r)

    # input your data here.
    g_data = 1.0 .+ cos.(rs) .* exp.( -(2r .- rs).^4 )

    dp = DiscretePairCorrelation(rs, g_data .- 1.0)

    medium = Acoustic(2; ρ=1.0, c=1.0)
    s1 = Specie(Acoustic(2; ρ=10.0, c=12.0),Circle(r); volume_fraction = 0.15)

    micro = Microstructure(medium,s1,dp)

    basis_order = 1
    ω = 0.6

    k_effs = wavenumbers(ω, micro; num_wavenumbers=2, basis_order=basis_order)

    # currently have no benchmark for 2D with any pair-correlation
    @test true
end
