export default class MyError {
  message: string;

  constructor() {
    this.message = "Another error";
  }

  boom() {
    throw new Error(this.message);
  }
}
