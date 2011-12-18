module Cacheable
	@@all = {}
	def new(id, *args)
    @@all[self] ||= {}
    if result = @@all[self][id]
      result.set(id, *args)
      result
    else
      @@all[self][id] = super(id, *args)
    end
	end
end