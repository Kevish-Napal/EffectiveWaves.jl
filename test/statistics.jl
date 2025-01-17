using EffectiveWaves
using LinearAlgebra, Statistics, Test
using CSV

@testset "Pair-correlation Percus-Yevick" begin

    # Load reference data
    stdir = if intersect(readdir(),["test"]) |> isempty
        ""
    else "test/"
    end

    # The data assume R = 1, where R is the minimum distance between the centres of any two spheres.
    file = CSV.File("$(stdir)data/P-Y_f=0.25.txt"; header = 1)
    distances = file.r
    dp_reference = file.field .- 1.0

    # NOTE: increasing the exclusion_distance would increase the effective volume fraction needed for PY. The saved data assumes and effective volume fraction of 25%

    φ = 0.25
    r = 0.9
    γ = 1.5

    # generate data from function in package
    s1 = Specie(
        Acoustic(3; ρ = 0.0, c = 0.0),
        Sphere(r),
        volume_fraction = φ / γ^3,
        separation_ratio = γ  # <---- changes the effective volume fraction
    );

    R = 2*outer_radius(s1) * s1.separation_ratio

    pairtype = PercusYevick(3; rtol=1e-3, maxevals = Int(2e5))

    # Need to scale the distance by R
    py = DiscretePairCorrelation(s1, pairtype; distances = R .* distances)

    i = findfirst(distances .> 1.0)

    @test norm(py.dp[i:end] - dp_reference[i:end]) / norm(dp_reference[i:end]) < 0.02
    @test abs(py.dp[i+1] - dp_reference[i+1]) / norm(dp_reference[i+1]) < 0.01
end

@testset "Pair-correlation tests" begin

    particle_medium = Acoustic(3; ρ=0.0, c=0.0);

    separation_ratio = 1.01

    s1 = Specie(
        particle_medium, Sphere(0.8), separation_ratio = separation_ratio
    );

    # minimal distance between particle centres
    a12 = 2.0 * s1.separation_ratio * outer_radius(s1)
    R = 10.0
    polynomial_order = 40

    pair_corr_inf(z) = hole_correction_pair_correlation([0.0,0.0,0.0],s1, [0.0,0.0,z],s1)

    # import EffectiveWaves: smooth_pair_corr_distance

    pair_corr_inf_smooth = smooth_pair_corr_distance(pair_corr_inf, a12; smoothing = 1.0, max_distance = 2R, polynomial_order = polynomial_order)

    # using Plots
    # rs = 0.0:0.1:(2R)
    # plot(rs,pair_corr_inf_smooth.(rs))
    # plot!(rs,pair_corr_inf.(rs))

    pair_radial = pair_radial_fun(pair_corr_inf_smooth, a12;
        sigma_approximation = false,
        polynomial_order = polynomial_order
    )

    r1 = 4.0; r2 = 4.2;
    cosθs = LinRange(0.6,1.0,200);


    pair_corr = pair_radial_to_pair_corr(pair_radial)

    p_corrs = map(eachindex(cosθs)) do i
        sinθ = sqrt(1.0 - cosθs[i]^2)
        x1 = [0.0, 0.0, r1]
        x2 = [r2 * sinθ, 0.0, r2 * cosθs[i]]
        pair_corr(x1,s1,x2,s1)
    end;

    p_rads = pair_radial.(r1,r2,cosθs);
    p_infs = pair_corr_inf_smooth.(sqrt.(r1^2 .+ r2.^2 .- 2r1 .* r2 .* cosθs))


    @test maximum(abs.(p_corrs - p_infs)) < 1e-3
    @test maximum(abs.(p_rads - p_infs)) < 1e-3

    polynomial_order = 90;
    pair_corr_inf(z) = hole_correction_pair_correlation([0.0,0.0,0.0],s1, [0.0,0.0,z],s1) #* (1 + sin(5*abs(z-a12)) * exp(-z))

    pair_radial = pair_radial_fun(pair_corr_inf, a12;
        sigma_approximation = true,
        # sigma = true,
        polynomial_order = polynomial_order,
        mesh_size = 12polynomial_order + 1
    )

    # polynomial_order = 10
    # sigmas = [one(T); sin.(pi .* ls[2:end] ./ (polynomial_order+1)) ./ (pi .* ls[2:end] ./ (polynomial_order+1))]
    # plot(sigmas)

    p_rads = pair_radial.(r1,r2,cosθs);
    p_infs = pair_corr_inf.(sqrt.(r1^2 .+ r2.^2 .- 2r1 .* r2 .* cosθs))
    # using Plots
    #
    # plot(cosθs,p_rads)
    # plot!(cosθs,p_infs)

    r1s = (20 * a12) .* rand(1000);
    r2s = (20 * a12) .* rand(1000);
    cosθs = LinRange(-1.0,1.0,1000);

    p_rads = pair_radial.(r1s,r2s,cosθs);
    p_infs = pair_corr_inf.(sqrt.(r1s.^2 .+ r2s.^2 .- 2r1s .* r2s .* cosθs));

    @test maximum(abs.(p_rads - p_infs)) < 0.8 # infinite sharp function may have point wise error ~ 0.5, but exceptionally rare.
    @test mean(abs.(p_rads - p_infs)) < 2e-3
end
