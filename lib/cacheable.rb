module Cacheable
	@@all = {}
	def new(id, *args)
    @@all[self] ||= {}
		@@all[self][id] ||= super()
    @@all[self][id].set(id, *args)
    @@all[self][id]
	end
end