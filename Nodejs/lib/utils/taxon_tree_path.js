//-----------------------------------------
//------------ADD NODE PATHS---------------
//-----------------------------------------
function find_path_to_all_nodes(){
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent : 1, _id : 0});
	for (var i =0; i< cursor.length();i++){
		var parent = tojson(cursor[i]["Parent"]);
		var path = find_path_from_node(eval(parent));
		path = path.split(',');
		traverse_update_path(path);
	}
}

function traverse_update_path(path){
	for (var i in path){
		var node = path[0];
		path.splice(0,1);
		db.taxonomy.update({Parent:node}, {$set:{Path:path}});
	}
}

function find_path_from_node(child){
	var data = db.taxonomy.findOne({Children : {$in : [ child ] }});
	if(data){
		var parent = find_path_from_node(data["Parent"]);
		return child + ',' + parent;
	}
	else return child;
}

//-----------------------------------------
//------------BUCKETING ALGO---------------
//-----------------------------------------
// PUBLIC
Date.prototype.timeNow = function () {
     return ((this.getHours() < 10)?"0":"") + this.getHours() +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds();
})

function bucketing(threshold, tag, prob){
	print("Initialing aggregated count of synsets: " + new Date().timeNow());
	initialise_count_agg(tag,prob);
	//find leaf nodes (easiest to find)
	print("Updating count of all nodes: " + new Date().timeNow());
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	//for each leaf node traverse its path updating the count of elements below it
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_descendant_count(path);			
	}
	print("Updating buckets: " + new Date().timeNow());
	var cursor = db.taxonomy.find({Children : [ ] }, {Parent:1, Path:1, _id:0});
	for (var i =0; i< cursor.length();i++){
		var parent = eval(tojson(cursor[i]["Parent"]));
		var path = eval(tojson(cursor[i]["Path"]));
		path.unshift(parent);
		traverse_update_bucket(path, threshold);			
	}
	//now return result
	//var res = db.plants.find({},{Image:1, Species:1, _id:0});
	//possible add constraint:
	//	where not count>=threshold, bucket != synset_id....this suggests the item is unclassifiable
	// then remove all excluded images
	print("Extrating final result set: " + new Date().timeNow());
	var res = db.plants.find({ Exclude:false, Count : {$gte : threshold}, $where : "this.Bucket != this.Synset_ID" } , {Image:1, Species:1, _id:0});	
	return res;	
}

// PRIVATE
var count_by_synset;

function initialise_count_agg(tag, prob){
	count_by_synset = new Object();
	var res = db.plants.aggregate(
		{ $match : {Component_Tag : tag , Component_Tag_Prob : { $gte : prob } , Exclude : false }}, 
		{ $group : { _id : "$Synset_ID", count : { $sum : 1 } }}
	);
	for (var i = 0 ; i< res.result.length; i++ ){
		count_by_synset[res.result[i]._id] = res.result[i].count;
	}
}

function traverse_update_descendant_count(path){
	var count = 0;
	for (var i in path){
		var node = path[i];
		if(count_by_synset[node]){
			count+=count_by_synset[node];
		};
		//defualt bucket to itself. we won't know until all nodes have been updated with their count if they need bucketed into an ancestor node
		db.plants.update({Synset_ID : node, Exclude : false}, {$inc : {Count : count}, $set : {Bucket : node}}, {multi : true});
		db.plants.update({Synset_ID : node, Exclude : true }, {$inc : {Count : 0    }, $set : {Bucket : node}}, {multi : true});
	}
}

function traverse_update_bucket(path, threshold){
	var running_count = 0;
	var index = 0;
	var bucket;
	while(running_count<threshold){
		for (var i in path){
			bucket = path[i];
			var data = db.plants.findOne({Synset_ID : bucket}, {Count:1 , _id:0});
			if(data){
				running_count += data.Count;
			}
			if(running_count >= threshold){
				index = i;
				break;
			}
		}
	}
	if(index>0){
		for(index; index>=0; index--){
			// if the proposed bucket is to be excluded then don't update it.
			var ex = db.plants.findOne({Synset_ID : bucket}, {Exclude:1, _id:0});
			if(!ex.Exclude){
				db.plants.update({Synset_ID : path[index]} , {$set : { Bucket : bucket }} , {multi : true});
			}
		}
	}
}
