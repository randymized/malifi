malifiMod= require(require('../_root'))

module.exports=
  preempting_router_: malifiMod.action_handlers.regex_router(
    /(\d+)\/(\d+)\/(\d+)/,
    '/date_'
  )
