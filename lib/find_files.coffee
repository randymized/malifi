_ = require('underscore')._
fs = require('fs')
path = require('path')
join = path.join

# find_files expects to be executed as a method of malifi.
# Populates malifi.files and matching_files_by_site.
exports = module.exports = find_files= (dirname, basename, cb)->
  dirname= '' if '/' == dirname
  re= new RegExp("^#{basename}(?:\\.(.+))?$")
  completed= 0
  findings= {}
  site_stack = this.site_stack.reverse()
  loops = site_stack.length
  oneDone= ()=>
    if loops == ++completed
      # all readdir results have been received and added to findings
      this.matching_files_by_site= findings
      candidates= {}
      for site in site_stack # merge, priortizing most specific site
        _.extend(candidates,findings[site])
      for ext,name of candidates
        candidates[ext]= name+'.'+ext if ext && '/' != ext
      this.files= candidates
      cb(candidates)
  for site in site_stack
    do ()->
      sitedir= site
      searchpath= join(sitedir,dirname)
      fs.readdir searchpath, (err,files)->
        if files
          for file in files
            m= re.exec(file)
            (findings[sitedir] ?= {})[m[1] ? ''] = join(searchpath,basename) if m
        finding = findings[sitedir]
        if finding?['']
          fs.stat finding[''], (err,stats)->
            if stats.isDirectory()
              finding['/']= finding['']
              delete finding['']
            oneDone()
        else
          oneDone()
