import { Injectable } from '@angular/core';
import * as _ from "lodash";
import * as odiff  from "odiff";

@Injectable({
  providedIn: 'root'
})
export class ToolsService {

  constructor() { }

  FormatData(Tab: any[], separator: string){
    // Clone Tab
    const myClonedArray = [];
    Tab.forEach(val => myClonedArray.push(Object.assign({}, val)));
     // Loop in Tab
    for( let item of myClonedArray){
      // Loop in each key of object
      for (let key of Object.keys(item)){
        let value = item[key];
        // Check if value of key is array
        if (Array.isArray(value)){
          item[key] = value.join(separator)
        }
      }
    }
    return myClonedArray
  }

  private modifyValue(itemtomodify: any, value: any, orientation: string){

  // let itemtomodify: any
  let NewObj: any
  if (typeof(itemtomodify) === 'object'){
    if (!Array.isArray(itemtomodify)){
      NewObj = {}
    }
    for(let key of Object.keys(itemtomodify)){
      if(typeof(itemtomodify[key]) !== 'object' && !Array.isArray(itemtomodify[key])){
        if(!itemtomodify[key]){
          NewObj[key] = ""
          NewObj['diffstatus'] = "Modified"
        }
        if(value.indexOf('-') > -1){
          NewObj['diffstatus'] = "Deleted"
        }
        if(value.indexOf('+') > -1){
          NewObj['diffstatus'] = "Created"
        }
        if (orientation === 'before' && itemtomodify[key]){
          NewObj[key] = value + itemtomodify[key]
        }
        if (orientation === 'after' && itemtomodify[key]){
          NewObj[key] = itemtomodify[key] + value
        }
      }
      else if (Array.isArray(itemtomodify[key])){
        NewObj[key] = []
        for (let i of itemtomodify[key]){
          NewObj[key].push(this.modifyValue(i, value, orientation))
        }
      }
      else{
        NewObj[key] = this.modifyValue(itemtomodify[key], value, orientation)
      }
    }
  }
  else{
    if (orientation === 'before'){
      NewObj = value + itemtomodify
    }
    if (orientation === 'after'){
      NewObj = itemtomodify + value
    }
  }
  return NewObj
  }

  // function returning an array with all difference between 2 input arrays
  diffArray(from: any[], to: any[]): any[]{
  // get whats deleted in list
  const deleteditems = _.differenceWith(from, to, _.isEqual)
  // get whats new insert in list
  const addeditems =  _.differenceWith(to, from, _.isEqual)
  // get tab with no differences 
  const equalitems = _.intersectionWith(from, to, _.isEqual)

  deleteditems.forEach( (part, index, theArray) => {
    theArray[index] = this.modifyValue(part, "||-", 'after')
  });

  addeditems.forEach( (part, index, theArray) => {
    theArray[index] = this.modifyValue(part, "+||", 'before')
  });
  let DiffResult: any[] = deleteditems.concat(addeditems)
  return DiffResult.concat(equalitems)
  }


async createDiffTab(resultdiff: any[], SrcTab: any[], DstTab: any[]): Promise<any>{

  console.log(resultdiff)
  let DiffResult  = Object.assign({}, SrcTab)

  // By default put Unchanged on diffstatus
  for (let prop in DiffResult) {
     if (DiffResult.hasOwnProperty(prop)) {
        DiffResult[prop]['diffstatus'] = "Unchanged"
     }
  }
  // loop in result of odiff
  for (let res of resultdiff){
    // check what kind of change
    if (res.type === 'add'){
      if (res.path.length >0){
        DiffResult[res.path[0]].diffstatus = "Modified"
        // loop in changed value
        for(let valresult of res.vals){
          // changed value is only object
          if(typeof(valresult) === 'object' && !Array.isArray(valresult)){
            // add +|| with the value and add to tab
            _.get(DiffResult, res.path.join('.')).push(this.modifyValue(valresult, "+||", 'before'))
          }
          else if (Array.isArray(_.get(DiffResult, res.path.join('.')))){
            _.get(DiffResult, res.path.join('.')).push("+||" + valresult)
          }
        }
      }
      else{
        for (let item of res.vals){
          item.diffstatus = "Created"
          _.assignIn(DiffResult, {item})
        }
      }
    }
    else if (res.type === 'set'){

      // if path length is superior to 1 so it a modification else it is a creation of an object
      DiffResult[res.path[0]].diffstatus = "Modified"
      
      if (res.path.length > 1){
        if (typeof(res.val) === 'object'){
          let Tabpathtoarray = res.path
          Tabpathtoarray.pop()
          let path = Tabpathtoarray.join('.')
          _.set(DiffResult, path, this.diffArray(_.get(SrcTab, path), _.get(DstTab, path)))
        }
        else{
        // Tag as modified each object in the path
        let i = 1
        for (let element of res.path){
          let sliceArray = res.path.slice(0, i)
          let objectelement = _.get(DiffResult, sliceArray.join('.'))          
          if(typeof(objectelement) === 'object' &&  !Array.isArray(objectelement)){
            if (objectelement.hasOwnProperty('diffstatus') && objectelement.diffstatus === "") {
              objectelement.diffstatus = 'Modified'
            }
          } 
          _.set(DiffResult, res.path.join('.'), this.modifyValue(res.val, "+||", 'before'))
          i++
        }
      }
      }
      else{
        _.set(DiffResult, res.path.join('.'), this.modifyValue(res.val, "+||", 'before'))
      }
    }
    
    else if (res.type === 'rm'){
      if (res.path.length >0 && DiffResult[res.path[0]].diffstatus != "Modified"){
        DiffResult[res.path[0]].diffstatus = "Modified"
        for (let valresult of res.vals){
          let pathtoarray = Object.assign([], res.path)
          let index = 0
          if(typeof(valresult) === 'object' && !Array.isArray(valresult)){
            let tab = _.get(DiffResult, pathtoarray.join('.'))
            index = _.findIndex(tab, valresult)
            pathtoarray.push(index)
            _.set(DiffResult, pathtoarray.join('.'), this.modifyValue(valresult, "||-", 'after'))
          }
        }

      }
      else{
        for (let valresult of res.vals){
          // valresult.diffstatus = "Deleted"
          let pathtoarray = Object.assign([], res.path)
          let index = 0
          if(typeof(valresult) === 'object' && !Array.isArray(valresult)){
            // search obj in array
            let tab = _.get(DiffResult, pathtoarray.join('.'))
            index = _.findIndex(tab, valresult)
            pathtoarray.push(index)
            _.set(DiffResult, pathtoarray.join('.'), this.modifyValue(valresult, "||-", 'after'))
          }
        }
      }
    }
  }
  return DiffResult
}


  async getDiffTab(SrcTab: any, DstTab: any){
  // Loop in Original Tab
  let diffresult = odiff(SrcTab, DstTab)
  // Create theDiff Array
  return await this.createDiffTab(diffresult, SrcTab, DstTab).then( result => {
    return result
  })
  }
}
