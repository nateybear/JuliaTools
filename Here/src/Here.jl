module Here

using Glob

export here

const base_folder = Ref{String}(dirname(Base.current_project()))

"""
    here(path...)
Get the absolute path by joining the base folder of the current project with the provided relative `path...`.
"""
function here(path...)
    return joinpath(base_folder[], path...)
end

"""
    i_am(filepath)
Set the base folder to the directory containing the specified `filepath` within the current project.
This function searches for `filepath` in the project directory and updates the base folder accordingly.
If the file is not found or if multiple matches are found, an error is raised.
"""
function i_am(filepath)
    project_root = dirname(Base.current_project())
    
    # Search for the exact file path in the project
    full_paths = glob("**/$filepath", project_root)
    
    if length(full_paths) == 0
        error("File $filepath not found in project directory.")
    elseif length(full_paths) > 1
        error("Multiple files matching $filepath found in project directory: $(full_paths)")
    else
        # Found exactly one match
        found_path = full_paths[1]
        
        # Extract the directory part that should become the new base
        # If filepath is "src/foo.jl" and found at "project_root/some/path/src/foo.jl"
        # then we want base_folder to be "project_root/some/path/src"
        relative_to_project = relpath(found_path, project_root)
        target_dir = dirname(relative_to_project)
        
        # Update base_folder to point to the directory containing the found file
        base_folder[] = joinpath(project_root, target_dir)

        @info "Here is now using $(base_folder[])"
        
        return nothing
    end
end

end
