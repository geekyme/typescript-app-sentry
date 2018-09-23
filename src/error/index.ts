export default class MyError {
  message: string;

  constructor() {
    this.message = "Hello error";
  }

  boom() {
    throw new Error(this.message);
  }
}
