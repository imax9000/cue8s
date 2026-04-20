if (.kind == "Deployment" or .kind == "DaemonSet") then
  .spec.template.spec.containers[] |= (
    if (.volumeMounts? != null) then
      .volumeMounts[] |= if (.subPath? == null) then del(.subPath) end
    end
    |
    if (.livenessProbe?.httpGet?.httpHeaders? == null) then
      del(.livenessProbe.httpGet.httpHeaders)
    end
    |
    if (.readinessProbe?.httpGet?.httpHeaders? == null) then
      del(.readinessProbe.httpGet.httpHeaders)
    end
  )
end
|
if (.metadata.annotations? == null) then
  del(.metadata.annotations)
end
