malifiMod= require('../../../..')

module.exports=
  preempting_router_: malifiMod.action_handlers.regex_router(
    /(\d+)\/(\d+)\/(\d+)/,
    '/mmddyy_'
  )
