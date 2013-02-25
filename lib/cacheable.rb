module Cacheable
	@@all = {}
	def new(id, *args)
    @@all[self] ||= {}
    if id and result = @@all[self][id]
      result.set(id, *args)
      result
    else
      @@all[self][id] = super(id, *args)
    end
  end
  def find(id)
    @@all[self][id]
  end
end