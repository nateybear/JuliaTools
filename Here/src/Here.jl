module Here

export here

function here(path...)
    base_folder = dirname(Base.current_project())
    return joinpath(base_folder, path...)
end

end
