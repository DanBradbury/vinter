vim9script
scriptencoding utf-8

var file_list_cache: list<string> = []
g:github_actions_last_window = win_getid()
b:added_syntaxes = []

var st: dict<any> = {
  'content': 'string'
}
st.content ..= 'nah'
echo st.content

export def OpenWorkflowFile(): void
  var line: string = getline('.')
  if line =~# '(PATH: \zs\S\+)'
    var workflow_path: string = matchstr(line, 'PATH: \zs[^ )]\+')
    var file: string = $'.github/workflows/{workflow_path}'
    if workflow_path != ''
      win_gotoid(g:github_actions_last_window)
      execute $'edit {file}'
      return
    endif
  else
    for lnum in range(line('.') - 1, 1, -1) # Iterate in reverse from the current line to the first line
      var buffer_line: string = getline(lnum)
      if buffer_line =~# '(PATH: \zs\S\+)'
        var workflow_path: string = matchstr(buffer_line, 'PATH: \zs[^ )]\+')
        win_gotoid(g:github_actions_last_window)
        execute $'edit .github/workflows/{workflow_path}'
        return
      endif
    endfor
  endif
enddef

export def OpenInGithub(): void
  var line: string = getline('.')
  if line =~# '(PATH: \zs\S\+)'
    var workflow_path: string = matchstr(line, 'PATH: \zs[^ )]\+')

    if workflow_path != ''
      var url: string = $'https://github.com/{g:github_actions_owner}/{g:github_actions_repo}/actions/workflows/{workflow_path}'
      call system($'open {shellescape(url)}')
    else
      echo "Error: Unable to determine repository or workflow ID."
    endif
  elseif line =~# '(Run ID: \zs\d\+)'
    var run_id: string = matchstr(line, '(Run ID: \zs\d\+')
    if run_id != ''
      var url: string = $'https://github.com/{g:github_actions_owner}/{g:github_actions_repo}/actions/runs/{run_id}'
      call system($'open {shellescape(url)}')
    endif
  endif
enddef

export def OpenWorkflowRun(): void
  # Get the current line
  var line: string = getline('.')

  # Check if the line contains a Run ID
  if line =~# '(Run ID: \zs\d\+)'
    var run_id: string = matchstr(line, 'Run ID: \zs\d\+')

    # Check if the run is already expanded
    var next_line: string = getline(line('.') + 1)
    if next_line =~# 'Job:'
      # Collapse the expanded run
      var current_line: number = line('.')
      while getline(current_line + 1) =~# 'Job:\|Step:'
        deletebufline('%', current_line + 1)
      endwhile
      return
    endif

    # Construct the API URL for the jobs in the run
    var api_url: string = printf(
          'repos/%s/%s/actions/runs/%s/jobs',
          g:github_actions_owner,
          g:github_actions_repo,
          run_id
          )

    # Fetch the jobs using the GitHub CLI
    var jobs_json: string = system('gh api ' .. api_url .. ' --jq ".jobs" 2>/dev/null')

    # Check if the gh CLI command succeeded
    if v:shell_error == 0
      # Parse the JSON into a Vim dictionary
      var jobs: string = json_decode(jobs_json)

      # Add the jobs below the run
      var current_line: number = line('.')
      for job in jobs
        var job_name: string = string(job['name'])
        var job_status: string = string(job['status'])
        var job_conclusion: string = string(job['conclusion'])
        var job_started_at: string = string(job['started_at'])

        var emoji: string = ''
        if match(job_conclusion, 'success') != -1
          emoji = '✅'
        elseif match(job_conclusion, 'failure') != -1
          emoji = '❌'
        else
          emoji = '⚠️'  # For other statuses like 'neutral', 'cancelled', etc.
        endif

        # Format the job details
        var job_details: string = printf(
              '            ➤ %s Job: %s',
              emoji,
              job_name
              )

        # Append the job details to the buffer
        append(current_line, job_details)
        current_line += 1

        # Add the steps for the job
        var steps: list = job['steps']
        for step in steps
          var step_name: string = string(step['name'])
          var step_status: string = string(step['status'])
          var step_conclusion: string = string(step['conclusion'])

          if match(step_conclusion, 'success') != -1
            emoji = '✅'
          elseif match(step_conclusion, 'failure') != -1
            emoji = '❌'
          else
            emoji = '⚠️'  # For other statuses like 'neutral', 'cancelled', etc.
          endif

          # Format the step details
          var step_details: string = printf(
                '                ➤ %s Step: %s',
                emoji,
                step_name
                )

          # Append the step details to the buffer
          append(current_line, step_details)
          current_line += 1
        endfor
      endfor
    else
      echoerr "Error: Unable to fetch jobs for Run ID: " .. run_id
    endif
  else
    echoerr "Error: Not a valid Run ID line."
  endif
enddef

