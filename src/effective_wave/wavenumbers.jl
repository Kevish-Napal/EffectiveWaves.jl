# Here we calculate the effective wavenumber and effective wave amplitudes, without any restriction to the volume fraction of particles and incident wave frequency.

"""
    wavenumbers(ω, medium, specie; kws...)

Returns all the possible effective wavenumbers with positive imaginary part when using a single type of particle called `specie`.
"""
wavenumbers(ω::Number, medium::PhysicalMedium, specie::Specie; kws...) = wavenumbers(ω, Microstructure(medium,[specie]); kws...)

wavenumbers(ω::Number, medium::PhysicalMedium, species::Species; kws...) = wavenumbers(ω, Microstructure(medium,species); kws...)

function wavenumbers(ω::Number, material::Material; kws...)
    return wavenumbers(ω, material.microstructure;
        # symmetry = Symmetry(source,material),
        kws...
    )
end

"""
    wavenumbers(ω, medium::PhysicalMedium, micro::Microstructure; kws...)

Returns all the possible effective wavenumbers with positive imaginary part. This function requires significantly numerical optimisation and so can be slow.
"""
function wavenumbers(ω::T, micro::Microstructure;
        num_wavenumbers::Int = 2, tol::T = 1e-5,
        # max_Imk::T = maximum(imag.(asymptotic_monopole_wavenumbers(ω, medium, micro; num_wavenumbers = num_wavenumbers + 3))),
        basis_order::Int = 3 * Int(round(maximum(outer_radius.(micro.species)) * ω / abs(micro.medium.c) )) + 1,
        # max_Rek::T = T(2) + T(20) * abs(real(wavenumber_low_volumefraction(ω, medium, species; verbose = false))),
        kws...) where T<:Number

    # For very low attenuation, need to search close to assymptotic root with a path method.
    # NOTE: oneof the key ingredients of these search methods are the estimates from the asymptotic results for monopole scatterers. We use these as initial guess and to determine the distance between roots.
    k_effs::Vector{Complex{T}} = wavenumbers_path(ω, micro;
        num_wavenumbers = num_wavenumbers,
        tol = tol,
        basis_order = basis_order, kws...
    )

    # Take only the num_wavenumbers wavenumbers with the smallest imaginary part.
    k_effs = k_effs[1:num_wavenumbers]

    if num_wavenumbers > 2
        # box_k = box_keff(ω, medium, species; tol = tol)
        # max_imag = max(3.0 * maximum(imag.(k_effs)), max_Imk)
        # max_imag = max(max_imag, box_k[2][2])
        # max_real = max(2.0 * maximum(real.(k_effs)), max_Rek)

        max_imag = maximum(imag.(k_effs))
        max_real = maximum(abs.(real.(k_effs)))
        box_k = [[-max_real,max_real], [0.0,max_imag]]

        k_effs2 = wavenumbers_bisection(ω, micro;
            # num_wavenumbers=num_wavenumbers,
            tol = tol, box_k = box_k,
            basis_order = basis_order,
            kws...)
        k_effs = [k_effs; k_effs2]
        k_effs = reduce_kvecs(k_effs, sqrt(tol))
        k_effs = sort(k_effs, by = imag)
    end

    return Complex{Float64}.(k_effs)
end
