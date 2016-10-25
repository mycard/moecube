let apps = require('./apps.json')

let result = apps.map((app)=>{
	console.error(app.id)
	let result = {}
	result.id = app.id
	result.name = app.name
	result.description = app.description
	let parent = apps.find(a=>app.id.startsWith(a.id+'-'));
	if(parent){
		result.category = "module"
		result.parent = parent.id
		result.tags = ["language"]
	} else {
		result.category = "game"
		result.tags = app.tags
	}
	result.dependency = {
    	"win32": [],
    	"darwin": ['wine']
    }
    let references = apps.filter(a=>a.id.startsWith(app.id+'-')).map(a=>a.id)
    result.references = {
    	"win32": references,
    	"darwin": references
    }
	result.author = app.author
	result.homepage = app.homepage
	result.locales = app.locales
	result.actions = app.actions
	result.version = app.version
	result.download = app.download
	result.news = app.news

	return result
})
.sort((a, b)=>a.id < b.id ? -1 : 1)

for (let app of result){
	console.error(app.id)
}

console.log(JSON.stringify(result))