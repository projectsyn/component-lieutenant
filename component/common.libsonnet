local mergeEnvVars(envs, additional) =
  local foldFn =
    function(acc, env)
      acc { [env.name]: env };
  local base = std.foldl(foldFn, envs, {});
  local final = std.foldl(foldFn, additional, base);
  [ final[k] for k in std.objectFields(final) ];

{
  MergeEnvVars: mergeEnvVars,
}
