if (-not $env:MIMO_API_KEY) {
  Write-Error "错误: 请先在用户环境变量中设置 MIMO_API_KEY"
  exit 1
}

python "$PSScriptRoot\server.py"
