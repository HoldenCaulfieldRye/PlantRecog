//-----------------------------------------
//------------BUCKETING ALGO---------------
//-----------------------------------------

var count_by_synset;

function bucketing(threshold, tag, prob){

	print('threshold = ' + threshold);
	print('tag = ' + tag);
	print('probibility = ' + prob);

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

}

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
	if(index>0){
		//would it be better to get a list of all synsets that need updating and bulk update them??? i.e.
		db.plants.update({ Synset_ID: {$in: path.slice(0,index)} , Exclude : false} , {$set : { Bucket : bucket }} , {multi : true});
		//for(index; index>=0; index--){
		//		db.plants.update({Synset_ID : path[index], Exclude : false} , {$set : { Bucket : bucket }} , {multi : true});
		//}
	}
}

Date.prototype.timeNow = function () { 
	return ((this.getHours() < 10)?"0":"") + this.getHours() +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds();
}

bucketing(THRES, TAG, PROB)

