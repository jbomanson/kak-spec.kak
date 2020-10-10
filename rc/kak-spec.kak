# Treat kak-spec files as kak files.
hook global BufCreate .*[.](kak-spec) %{
    set-option buffer filetype kak
}

hook global ModuleLoaded kak %{
    require-module kak-spec
}

# NOTE: This is adapted from plug.kak
# since we want to add highlighters to kak filetype we need to require kak module
provide-module kak-spec %@
    require-module kak

    try %$
        add-highlighter shared/kakrc/code/kak_spec_keywords   regex \b(kak-spec)\b 0:keyword
        add-highlighter shared/kakrc/code/kak_spec_attributes regex -(title|input|eval|exec)\b|-expect-\S* 0:attribute
    $ catch %$
        echo -debug "kak-spec.kak: Can't declare highlighters for 'kak' filetype."
        echo -debug "          Detailed error: %val{error}"
    $
@
