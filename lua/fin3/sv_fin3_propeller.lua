local dt = engine.TickInterval()

Fin3.propeller = {}

function Fin3.propeller:new(ply, ent, data)
    local self = setmetatable({}, {__index = Fin3.propeller})
    self.ply = ply
    self.ent = ent
    self.data = data
    self.last = CurTime()
    self.next = self.last + dt
    self:initialize()
    return self
end